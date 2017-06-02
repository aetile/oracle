CREATE OR REPLACE PACKAGE sppurpkg
IS
    PROCEDURE purge(in_days_older_than IN INTEGER);
END sppurpkg;
/

SET TERMOUT ON
SHOW ERRORS

SET TERMOUT OFF
CREATE OR REPLACE PACKAGE BODY sppurpkg
IS
    PROCEDURE purge(in_days_older_than IN INTEGER)
    IS
        CURSOR get_snaps(in_days IN INTEGER) IS
            SELECT s.rowid,
                s.snap_id,
                s.dbid,
                s.instance_number
                FROM stats$snapshot s,
                sys.v_$database d,
                sys.v_$instance i
                WHERE s.dbid = d.dbid
                AND s.instance_number = i.instance_number
                AND s.snap_time < TRUNC(SYSDATE) - in_days;
        errcontext VARCHAR2(100);
        errmsg VARCHAR2(1000);
        save_module VARCHAR2(48);
        save_action VARCHAR2(32);
    BEGIN
        errcontext := 'save settings of DBMS_APPLICATION_INFO';
        dbms_application_info.read_module(save_module, save_action);
        dbms_application_info.set_module('SPPURPKG.PURGE', 'begin');
        errcontext := 'open/fetch get_snaps';
        dbms_application_info.set_action(errcontext);
        FOR x IN get_snaps(in_days_older_than)
        LOOP
            errcontext := 'delete (cascade) STATS$SNAPSHOT';
            dbms_application_info.set_action(errcontext);
            DELETE
                FROM stats$snapshot
                WHERE ROWID = x.rowid;
            errcontext := 'delete "dangling" STATS$SQLTEXT rows';
            dbms_application_info.set_action(errcontext);
            DELETE
                FROM stats$sqltext
                WHERE (old_hash_value, text_subset) not in
                    (SELECT /*+ hash_aj (ss) */ old_hash_value, text_subset
                        FROM stats$sql_summary ss
                    );
            errcontext := 'delete "dangling" STATS$DATABASE_INSTANCE rows';
            dbms_application_info.set_action(errcontext);
            DELETE
                FROM stats$database_instance i
                WHERE i.instance_number = x.instance_number
                AND i.dbid = x.dbid
                AND NOT EXISTS
                    (SELECT 1
                        FROM stats$snapshot s
                        WHERE s.dbid = i.dbid
                        AND s.instance_number = i.instance_number
                        AND s.startup_time = i.startup_time
                    );
            errcontext := 'delete "dangling" STATS$STATSPACK_PARAMETER rows';
            dbms_application_info.set_action(errcontext);
            DELETE
                FROM stats$statspack_parameter p
                WHERE p.instance_number = x.instance_number
                AND p.dbid = x.dbid
                AND NOT EXISTS
                    (SELECT 1
                        FROM stats$snapshot s
                        WHERE s.dbid = p.dbid
                        AND s.instance_number = p.instance_number
                    );
            errcontext := 'fetch/close get_snaps';
            dbms_application_info.set_action(errcontext);
        END LOOP;
        errcontext := 'restore saved settings of DBMS_APPLICATION_INFO';
        dbms_application_info.set_module(save_module, save_action);
    EXCEPTION
        WHEN OTHERS THEN
            errmsg := sqlerrm;
            dbms_application_info.set_module(save_module, save_action);
            raise_application_error(-20000, errcontext || ': ' || errmsg);
    END purge;
END sppurpkg;
/
SET TERMOUT ON
SHOW ERRORS
exit

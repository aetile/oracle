SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool postDBCreation.log append
execute DBMS_AUTO_TASK_ADMIN.disable();
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catbundleapply.sql;
select 'utl_recomp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;
execute utl_recomp.recomp_serial();
select 'utl_recomp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
create spfile='+DATA/SID_/spfileSID_.ora' FROM pfile='/opt/app/oracle/11.2.0.4/base/admin/SID_/scripts/initSID_.ora';
shutdown immediate;
host /opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl enable database -d SID_;
host /opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl start database -d SID_;
connect "SYS"/"&&sysPassword" as SYSDBA
spool off

SET PAGESIZE 100
SET LINESIZE 265
SET TRIMOUT ON TRIMS ON PAGESIZE 999

COLUMN tablespace_name FORMAT A20
COLUMN file_name FORMAT A50

DECLARE v_tbs number;

BEGIN
select count(*) into v_tbs from dba_tables where table_name ='TBS_HISTORY';

if v_tbs >0 then
EXECUTE IMMEDIATE 'DELETE FROM SYS.TBS_HISTORY WHERE TRUNC(SNAP_DATE) = TRUNC(SYSDATE)';
EXECUTE IMMEDIATE 'INSERT INTO SYS.TBS_HISTORY
SELECT SYSDATE SNAP_DATE, df.tablespace_name,
       tb.bigfile,
       df.autoextensible,
       df.size_mb,
       df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)) used_mb,
       NVL(f.free_mb,0) free_mb,
       df.max_size_mb,
       NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb) AS max_free_mb,
       TO_CHAR(ROUND((df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)))/max_size_mb*100,0)) pct_used
FROM   (SELECT tablespace_name,
               autoextensible,
               TRUNC(SUM(bytes)/1024/1024) AS size_mb,
               TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
        FROM   dba_data_files
        GROUP BY TABLESPACE_NAME,AUTOEXTENSIBLE) df,
       (SELECT tablespace_name, TRUNC(SUM(bytes)/1024/1024) AS free_mb
        FROM dba_free_space
        GROUP BY tablespace_name) f,
        dba_tablespaces tb
WHERE  df.tablespace_name =f.tablespace_name (+)
       AND df.tablespace_name = tb.tablespace_name
UNION
SELECT SYSDATE SNAP_DATE, df.tablespace_name,
       tb.bigfile,
       df.autoextensible,
       df.size_mb,
       df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)) used_mb,
       NVL(f.free_mb,0) free_mb,
       df.max_size_mb,
       NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb) AS max_free_mb,
       TO_CHAR(ROUND((df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)))/max_size_mb*100,0)) pct_used
FROM   (SELECT tablespace_name,
               autoextensible,
               TRUNC(SUM(bytes)/1024/1024) AS size_mb,
               TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
        FROM   dba_temp_files
        GROUP BY TABLESPACE_NAME,AUTOEXTENSIBLE) df,
       (SELECT tablespace_name, TRUNC(SUM(bytes_free)/1024/1024) AS free_mb
        FROM v$temp_space_header
        GROUP BY tablespace_name) f,
        dba_tablespaces tb
WHERE  df.tablespace_name = f.tablespace_name (+)
       AND df.tablespace_name = tb.tablespace_name
ORDER BY 2 desc';
EXECUTE IMMEDIATE 'COMMIT';
else
EXECUTE IMMEDIATE 'CREATE TABLE SYS.TBS_HISTORY AS SELECT SYSDATE SNAP_DATE, df.tablespace_name,
       tb.bigfile,
       df.autoextensible,
       df.size_mb,
       df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)) used_mb,
       NVL(f.free_mb,0) free_mb,
       df.max_size_mb,
       NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb) AS max_free_mb,
       TO_CHAR(ROUND((df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)))/max_size_mb*100,0)) pct_used
FROM   (SELECT tablespace_name,
               autoextensible,
               TRUNC(SUM(bytes)/1024/1024) AS size_mb,
               TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
        FROM   dba_data_files
        GROUP BY TABLESPACE_NAME,AUTOEXTENSIBLE) df,
       (SELECT tablespace_name, TRUNC(SUM(bytes)/1024/1024) AS free_mb
        FROM dba_free_space
        GROUP BY tablespace_name) f,
        dba_tablespaces tb
WHERE  df.tablespace_name =f.tablespace_name (+)
       AND df.tablespace_name = tb.tablespace_name
UNION
SELECT SYSDATE SNAP_DATE, df.tablespace_name,
       tb.bigfile,
       df.autoextensible,
       df.size_mb,
       df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)) used_mb,
       NVL(f.free_mb,0) free_mb,
       df.max_size_mb,
       NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb) AS max_free_mb,
       TO_CHAR(ROUND((df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)))/max_size_mb*100,0)) pct_used
FROM   (SELECT tablespace_name,
               autoextensible,
               TRUNC(SUM(bytes)/1024/1024) AS size_mb,
               TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
        FROM   dba_temp_files
        GROUP BY TABLESPACE_NAME,AUTOEXTENSIBLE) df,
       (SELECT tablespace_name, TRUNC(SUM(bytes_free)/1024/1024) AS free_mb
        FROM v$temp_space_header
        GROUP BY tablespace_name) f,
        dba_tablespaces tb
WHERE  df.tablespace_name = f.tablespace_name (+)
       AND df.tablespace_name = tb.tablespace_name
ORDER BY 2 desc';
EXECUTE IMMEDIATE 'ALTER TABLE SYS.TBS_HISTORY ADD CONSTRAINT PK_TBS_HISTORY PRIMARY KEY (tablespace_name,snap_date)';
end if;
END;
/

SELECT --SNAP_DATE, 
       tablespace_name,
       bigfile,
       autoextensible,
       size_mb,
       used_mb,
       free_mb,
       max_size_mb,
       max_free_mb,
       TO_CHAR(pct_used) || '%' pct_used
FROM SYS.TBS_HISTORY WHERE TRUNC(SNAP_DATE) = TRUNC(SYSDATE) ORDER BY TABLESPACE_NAME ASC;


SET PAGESIZE 100
SET LINESIZE 265
SET TRIMOUT ON TRIMS ON PAGESIZE 999

COLUMN tablespace_name FORMAT A20

SELECT df.tablespace_name, TO_CHAR(ROUND((df.max_size_mb-(NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb)))/max_size_mb*100,0)) || '%' pct_used, ROUND( (NVL(f.free_mb,0) + (df.max_size_mb - df.size_mb))/1024) AS max_free_gb
FROM   (SELECT tablespace_name,
               TRUNC(SUM(bytes)/1024/1024) AS size_mb,
               TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
        FROM   dba_temp_files
        GROUP BY TABLESPACE_NAME) df,
       (SELECT tablespace_name, TRUNC(SUM(bytes_free)/1024/1024) AS free_mb
        FROM v$temp_space_header
        GROUP BY tablespace_name) f
WHERE  df.tablespace_name ='TEMP'
and df.tablespace_name = f.tablespace_name (+);

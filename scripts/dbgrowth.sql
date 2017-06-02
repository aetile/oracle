SELECT TO_CHAR(a1.snap_date,'yyyy/mm/dd') "Current Date", a1.tablespace_name, ROUND(a1.used_mb/1024,2) "Current Size GB", TO_CHAR(a2.snap_date,'yyyy/mm:dd') "Previous Date", ROUND(a2.used_mb/1024,2) "Previous Size MB", a1.used_mb - a2.used_mb "Delta MB", ROUND(100*(a1.used_mb - a2.used_mb)/a1.max_size_mb,2) "Delta %" 
FROM SYS.TBS_HISTORY a1, SYS.TBS_HISTORY a2
WHERE a1.tablespace_name = 'KYR_DATA'
and a2.tablespace_name = 'KYR_DATA'
and a1.snap_date = (SELECT MAX(snap_date) from SYS.TBS_HISTORY WHERE snap_date >= SYSDATE -7)
and a2.snap_date = (SELECT MIN(snap_date) from SYS.TBS_HISTORY WHERE snap_date >= SYSDATE -7);

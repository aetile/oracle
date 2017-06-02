set lines 200 pages 9999

SELECT TO_CHAR(a.snap_time,'dd/mm/yyyy') "Snap Time",
       FUNCTION_NAME "Process",
       TO_CHAR(TRUNC(AVG(a.reads)),'999,999,999,990') "Nb Reads",
       TO_CHAR(TRUNC(AVG(a.reads/(24*60*60*(a.snap_time - b.snap_time)))),'999,999,999,990') "Read IOPS",
       TRUNC(AVG(a.reads_GB)) "Reads GB",
       TO_CHAR(TRUNC(AVG(a.writes)),'999,999,999,990') "Nb Writes",
       TO_CHAR(TRUNC(AVG(a.writes/(24*60*60*(a.snap_time - b.snap_time)))),'999,999,999,990') "Write IOPS",
       TRUNC(AVG(a.writes_GB)) "Writes GB"
FROM (SELECT sn.snap_id, sn.snap_time, sn.startup_time, n.FUNCTION_NAME,
       SUM(f.SMALL_READ_REQS + f.LARGE_READ_REQS) reads,
       TRUNC(SUM((f.SMALL_READ_MEGABYTES + f.LARGE_READ_MEGABYTES)/1024),2) reads_GB,
       SUM(f.SMALL_WRITE_REQS + f.LARGE_WRITE_MEGABYTES) writes,
       TRUNC(SUM((f.SMALL_WRITE_MEGABYTES + f.LARGE_WRITE_MEGABYTES)/1024),2) writes_GB
      FROM STATS$IOSTAT_FUNCTION_NAME n, STATS$IOSTAT_FUNCTION f, STATS$SNAPSHOT sn
      WHERE n.FUNCTION_ID = f.FUNCTION_ID
       AND f.snap_id = sn.snap_id
       AND sn.snap_time >= SYSDATE -7
       AND sn.instance_number = (SELECT instance_number FROM v$instance)
       --AND n.FUNCTION_NAME in ('RMAN','DBWR','LGWR','ARCH','Direct Reads','Direct Writes')
      AND n.FUNCTION_NAME in ('RMAN','DBWR','LGWR','Direct Reads','Direct Writes')
      GROUP BY sn. snap_id, sn.snap_time, sn.startup_time, n.FUNCTION_NAME) a,
      (select snap_id, snap_time, startup_time from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance)) b
WHERE a.startup_time = (select max(startup_time) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance))
and b.snap_id = (SELECT MAX(snap_id) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_id < a.snap_id)
GROUP BY TO_CHAR(a.snap_time,'dd/mm/yyyy'), a.function_name
ORDER BY 1 DESC,2 ASC;


--select to_char(sn.snap_time,'dd/mm/yyyy') "Snap Time",
--to_char(sn.STARTUP_TIME,'dd/mm/yyyy hh:mi:ss') "Startup Time", 
--AVG(rd1.value-rd2.value) "Read IOs",
--AVG(wr1.value-wr2.value) "Write IOs",
--trunc(AVG((rd1.value-rd2.value)/((sn.snap_time-sn2.snap_time)*24*60*60))) "Read IOPS",
--trunc(AVG((wr1.value-wr2.value)/((sn.snap_time-sn2.snap_time)*24*60*60))) "Write IOPS",
--trunc(AVG((rd1.value-rd2.value + wr1.value-wr2.value)/((sn.snap_time-sn2.snap_time)*24*60*60))) "Total IOPS"
--from (select snap_id,value from stats$sysstat where name = 'physical reads') rd1,
--(select snap_id,value from stats$sysstat where name = 'physical reads') rd2,
--(select snap_id,value from stats$sysstat where name = 'physical writes') wr1,
--(select snap_id,value from stats$sysstat where name = 'physical writes') wr2,
--(select snap_id, snap_time, STARTUP_TIME from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_time >= SYSDATE -7 and startup_time = (select MAX(startup_time) from stats$snapshot)) sn,
--(select snap_id, snap_time, STARTUP_TIME from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_time >= SYSDATE -7 and startup_time = (select MAX(startup_time) from stats$snapshot)) sn2
--where rd1.snap_id = sn.snap_id
--and wr1.snap_id = sn.snap_id
--and rd2.snap_id = (select MAX(snap_id) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_id < rd1.snap_id)
--and wr2.snap_id = (select MAX(snap_id) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_id < wr1.snap_id)
--and sn2.snap_id = rd2.snap_id
--to_char(sn.snap_time,'dd/mm/yyyy'), to_char(sn.STARTUP_TIME,'dd/mm/yyyy hh:mi:ss')
--order by 1 DESC;

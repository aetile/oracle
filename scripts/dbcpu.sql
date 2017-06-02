set pages 999 lines 200
col "Avg User %" for a20
col "Avg Background %" for a20
col "Avg USer CPU %" for a20
col "Avg Background CPU %" for a20
col "Avg Parse %" for a20
col "Avg SQL exec %" for a20
col "Avg RMAN exec %" for a20

SELECT TO_CHAR(a.snap_time,'dd/mm/yyyy') "Snap Time",
       --TO_CHAR(TRUNC(24*60*60*(a.snap_time - b.snap_time)),'999,999,999,990') "Elapsed Time (s)", a.snap_id, b.snap_id,
       --TO_CHAR(TRUNC(AVG(NVL(dbt1.time_s -dbt2.time_s,0))),'999,999,999,990') "Avg User Time (s)",
       TO_CHAR(TRUNC(AVG(100*NVL(dbt1.time_s -dbt2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg User %",
       --TO_CHAR(TRUNC(AVG(NVL(bkt1.time_s,0) -NVL(bkt2.time_s,0))),'999,999,999,990') "Avg Back. Time (s)",
       TO_CHAR(TRUNC(AVG(100*NVL(bkt1.time_s -bkt2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg Background %",
       --TO_CHAR(TRUNC(AVG(NVL(dbc1.time_s -dbc2.time_s,0))),'999,999,999,990') "Avg User CPU Time (s)",
       TO_CHAR(TRUNC(AVG(100*NVL(dbc1.time_s -dbc2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg User CPU %",
       --TO_CHAR(TRUNC(AVG(NVL(bkc1.time_s -bkc2.time_s,0))),'999,999,999,990') "Avg Back. CPU Time (s)",
       TO_CHAR(TRUNC(AVG(100*NVL(bkc1.time_s -bkc2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg Background CPU %",
       --TO_CHAR(TRUNC(AVG(NVL(pars1.time_s -pars2.time_s,0))),'999,999,999,990') "Avg Parse Time (s)",
       TO_CHAR(TRUNC(100*AVG(NVL(pars1.time_s -pars2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg Parse %",
       --TO_CHAR(TRUNC(AVG(NVL(sql1.time_s -sql2.time_s,0))),'999,999,999,990') "Avg SQL Exec Time (s)",
       TO_CHAR(TRUNC(100*AVG(NVL(sql1.time_s -sql2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg SQL exec %",
       --TO_CHAR(TRUNC(AVG(NVL(rman1.time_s -rman2.time_s,0))),'999,999,999,990') "Avg RMAN Exec Time (s)"--,
       TO_CHAR(TRUNC(100*AVG(NVL(rman1.time_s -rman2.time_s,0)/(24*60*60*l.CPU_COUNT_CURRENT*(a.snap_time - b.snap_time))),2),'990.00') "Avg RMAN exec %"
FROM (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
      AND n.STAT_NAME = 'DB time'
      GROUP BY f.snap_id, n.STAT_NAME) dbt1,
      (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
      AND n.STAT_NAME = 'DB time'
      GROUP BY f.snap_id, n.STAT_NAME) dbt2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'background elapsed time'
      GROUP BY f.snap_id, n.STAT_NAME) bkt1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'background elapsed time'
      GROUP BY f.snap_id, n.STAT_NAME) bkt2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME ='DB CPU'
      GROUP BY f.snap_id, n.STAT_NAME) dbc1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME ='DB CPU'
      GROUP BY f.snap_id, n.STAT_NAME) dbc2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'background cpu time'
      GROUP BY f.snap_id, n.STAT_NAME) bkc1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'background cpu time'
      GROUP BY f.snap_id, n.STAT_NAME) bkc2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'parse time elapsed'
      GROUP BY f.snap_id, n.STAT_NAME) pars1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'parse time elapsed'
      GROUP BY f.snap_id, n.STAT_NAME) pars2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'sql execute elapsed time'
      GROUP BY f.snap_id, n.STAT_NAME) sql1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'sql execute elapsed time'
      GROUP BY f.snap_id, n.STAT_NAME) sql2,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'RMAN cpu time (backup/restore)'
      GROUP BY f.snap_id, n.STAT_NAME) rman1,
     (SELECT f.snap_id, n.STAT_NAME, TRUNC(MAX(f.value/1000000),2) time_s
      FROM stats$time_model_statname n, stats$sys_time_model f
      WHERE n.STAT_ID = f.STAT_ID
       AND n.STAT_NAME = 'RMAN cpu time (backup/restore)'
      GROUP BY f.snap_id, n.STAT_NAME) rman2,
--      (select snap_id, snap_time from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance)) b,
      stats$snapshot a, stats$snapshot b, v$license l
WHERE a.instance_number = (SELECT instance_number FROM v$instance)
and a.startup_time = (select max(startup_time) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance))
and a.snap_time >= SYSDATE -7
and b.snap_id = (SELECT MIN(snap_id) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance) and snap_id < a.snap_id and startup_time = (select max(startup_time) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance)))
and dbt1.snap_id = a.snap_id
AND bkt1.snap_id = a.snap_id
AND dbc1.snap_id = a.snap_id
AND bkc1.snap_id = a.snap_id
AND pars1.snap_id = a.snap_id
AND sql1.snap_id = a.snap_id
AND rman1.snap_id = a.snap_id
and dbt2.snap_id = b.snap_id
AND bkt2.snap_id = b.snap_id
AND dbc2.snap_id = b.snap_id
AND bkc2.snap_id = b.snap_id
AND pars2.snap_id = b.snap_id
AND sql2.snap_id = b.snap_id
AND rman2.snap_id = b.snap_id
GROUP BY TO_CHAR(a.snap_time,'dd/mm/yyyy') --, TO_CHAR(TRUNC(24*60*60*(a.snap_time - b.snap_time)),'999,999,999,990'), a.snap_id,b.snap_id
ORDER BY 1 DESC;

--select to_char(sn.snap_time,'dd/mm/yyyy') "Snap Time",
--       TRUNC(AVG(24*60*60*(sn.snap_time - dt.snap_time)),2) "Avg Elapsed (s)", 
--       --TRUNC(AVG((st1.value -h1.value)/100),1) "Avg CPU Total (s)",
--       TRUNC(AVG((st1.value -h1.value)/(24*60*60*cpu.num*(sn.snap_time - dt.snap_time))),1) "Avg CPU Total %",
--       --TRUNC(AVG((st1.value -st2.value -st3.value -h1.value + h2.value +h3.value)/100),1) "Avg CPU Other (s)",
--       TRUNC(AVG((st1.value -st2.value -st3.value -h1.value + h2.value +h3.value)/(24*60*60*cpu.num*(sn.snap_time - dt.snap_time))),1) "Avg CPU Other %",
--       --TRUNC(AVG((st2.value -h2.value)/100),1) "Avg CPU Recursive (s)",
--       TRUNC(AVG((st2.value -h2.value)/(24*60*60*cpu.num*(sn.snap_time - dt.snap_time))),1) "Avg CPU Recursive %",
--       --TRUNC(AVG((st3.value -h3.value)/100),1) "Avg CPU Parse (s)",
--       TRUNC(AVG((st3.value -h3.value)/(24*60*60*cpu.num*(sn.snap_time - dt.snap_time))),1) "Avg CPU Parse %"
--from (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='CPU used by this session') st1,
--     (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='recursive cpu usage') st2,
--     (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='parse time cpu') st3,
--     (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='CPU used by this session') h1,
--     (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='recursive cpu usage') h2,
--     (select snap_id,NAME,value from STATS$SYSSTAT where NAME ='parse time cpu') h3,
--     (select snap_id, snap_time from STATS$SNAPSHOT where instance_number = (SELECT instance_number FROM v$instance)) dt,
--     (select snap_id, snap_time, startup_time from STATS$SNAPSHOT where instance_number = (SELECT instance_number FROM v$instance)) sn,
--     (select CPU_COUNT_CURRENT num from v$license) cpu
--WHERE sn.snap_time >= SYSDATE -7
--AND sn.startup_time = (select MAX(startup_time) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance))
--AND st1.snap_id = sn.snap_id
--AND st2.snap_id = st1.snap_id
--AND st3.snap_id = st1.snap_id
--AND h1.snap_id = (select MAX(snap_id) from STATS$SNAPSHOT where instance_number = (SELECT instance_number FROM v$instance) and snap_id < st1.snap_id)
--AND h2.snap_id = (select MAX(snap_id) from STATS$SNAPSHOT where instance_number = (SELECT instance_number FROM v$instance) and snap_id < st2.snap_id)
--AND h3.snap_id = (select MAX(snap_id) from STATS$SNAPSHOT where instance_number = (SELECT instance_number FROM v$instance) and snap_id < st3.snap_id)
--AND h2.snap_id = h1.snap_id
--AND h3.snap_id = h1.snap_id
--AND dt.snap_id = h1.snap_id
--group by to_char(sn.snap_time,'dd/mm/yyyy')
--order by 1 DESC;


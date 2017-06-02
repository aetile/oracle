set lines 200 pages 9999

select to_char(sn.snap_time,'dd/mm/yyyy') "Snap Time", st1.name POOL, ROUND(100*(AVG((st1.db_block_gets + st1.consistent_gets -st1.physical_reads -st2.db_block_gets - st2.consistent_gets +st2.physical_reads)/(st1.db_block_gets + st1.consistent_gets -st2.db_block_gets - st2.consistent_gets))),2) "Avg Hit Ratio%"
from stats$buffer_pool_statistics st1, stats$buffer_pool_statistics st2, stats$snapshot sn
where st1.snap_id = sn.snap_id
and sn.instance_number = (SELECT instance_number FROM v$instance)
and st2.snap_id = (select MAX(snap_id) from stats$buffer_pool_statistics where instance_number = (SELECT instance_number FROM v$instance) and snap_id < st1.snap_id)
and sn.snap_time >= SYSDATE -7
and sn.startup_time = (select max(startup_time) from stats$snapshot where instance_number = (SELECT instance_number FROM v$instance))
group by to_char(sn.snap_time,'dd/mm/yyyy'), st1.name
order by 1 DESC;

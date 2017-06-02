set lines 200 pages 9999
col "Module" for a50

SELECT * FROM (SELECT DISTINCT text_subset SQL, sql_id "SQL id", old_hash_value "Hash Value", executions, ROUND (cpu_time / (executions * 1000000), 0) "Avg CPU Time", ROUND (elapsed_time / (executions * 1000000), 0) "Avg Elapsed Time", module, TO_CHAR (last_active_time, 'dd-mm-yy hh24:mi') "Last Executed"
FROM stats$sql_summary
WHERE executions > 0
AND LOWER (text_subset) NOT LIKE 'insert%'
AND last_active_time >= SYSDATE -7
ORDER BY 6 DESC)
WHERE ROWNUM <=10;

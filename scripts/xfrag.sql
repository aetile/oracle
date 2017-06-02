SELECT a.table_owner, a.TABLE_NAME, b.index_name, TO_CHAR(TRUNC(a.DELETES/c.NUM_ROWS,4)*100,'9990.00') || '%' PCT_DELETED, a.DELETES DELETED, c.NUM_ROWS
from dba_tab_modifications a, dba_indexes b, dba_tab_statistics c
where a.TABLE_NAME = b.TABLE_NAME
and a.TABLE_NAME = c.TABLE_NAME
AND c.NUM_ROWS >0
and (a.DELETES/c.NUM_ROWS > 0.05 OR a.DELETES > 100000)
and b.index_type = 'NORMAL'
and a.table_owner NOT LIKE '%SYS%'
order by 4 DESC;

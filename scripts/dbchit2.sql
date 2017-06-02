select name, db_block_gets, consistent_gets, physical_reads, '%' || TO_CHAR(ROUND(100*((db_block_gets + consistent_gets -physical_reads)/(db_block_gets + consistent_gets)),2), '90.99') "Cache Hit"
from v$buffer_pool_statistics;

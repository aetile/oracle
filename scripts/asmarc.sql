SELECT name ASM_GROUP, '%' || TO_CHAR(ROUND((1- (free_mb / total_mb))*100, 2), '990.99') pct_used FROM v$asm_diskgroup WHERE name like '%ARC%';

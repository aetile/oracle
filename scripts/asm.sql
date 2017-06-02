SET PAGESIZE 100
SET LINESIZE 265
SET TRIMOUT ON TRIMS ON PAGESIZE 999

COLUMN tablespace_name FORMAT A20
COLUMN file_name FORMAT A50

DECLARE v_asm number;

BEGIN
select count(*) into v_asm from dba_tables where table_name ='ASM_DISKGROUP_HISTORY';

if v_asm >0 then
EXECUTE IMMEDIATE 'DELETE FROM sys.asm_diskgroup_history WHERE TRUNC(SNAP_DATE) = TRUNC(SYSDATE)';
EXECUTE IMMEDIATE 'insert into sys.asm_diskgroup_history select sys.asm_diskgroup_history_seq.NEXTVAL, SYSDATE, a.* from v$asm_diskgroup a';
EXECUTE IMMEDIATE 'COMMIT';
else
EXECUTE IMMEDIATE 'create table sys.asm_diskgroup_history as select sys.asm_diskgroup_history_seq.NEXTVAL SNAP_ID, SYSDATE SNAP_DATE, a.* from v$asm_diskgroup a';
EXECUTE IMMEDIATE 'create sequence sys.asm_diskgroup_history_seq';
end if;

END;
/

SELECT name ASM_GROUP, group_number, state, TRUNC(total_mb/1024,1) total_gb, TRUNC(free_mb/1024,1) free_gb, TRUNC(usable_file_mb/1024,1) usable_gb, TRUNC((total_mb-usable_file_mb)/1024,1) used_gb, TO_CHAR(TRUNC(100*(1-(usable_file_mb/total_mb)),1)) || '%' pct_used 
FROM V$ASM_DISKGROUP
order by 4 desc;


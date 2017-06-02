SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool interMedia.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/ord/im/admin/iminst.sql;
spool off

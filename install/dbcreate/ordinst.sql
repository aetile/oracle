SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool ordinst.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/ord/admin/ordinst.sql SYSAUX SYSAUX;
spool off

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /opt/app/oracle/11.2.0.4/base/admin/SID_/scripts/CreateClustDBViews.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catclust.sql;
spool off

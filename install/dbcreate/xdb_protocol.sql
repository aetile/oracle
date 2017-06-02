SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool xdb_protocol.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catqm.sql change_on_install SYSAUX TEMP YES;
connect "SYS"/"&&sysPassword" as SYSDBA
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catxdbj.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catrul.sql;
spool off

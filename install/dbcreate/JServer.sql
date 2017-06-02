SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool JServer.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/javavm/install/initjvm.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/xdk/admin/initxml.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/xdk/admin/xmlja.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catjava.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catexf.sql;
spool off

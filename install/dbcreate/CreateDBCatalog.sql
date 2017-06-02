SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool CreateDBCatalog.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catalog.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catblock.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catproc.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/catoctk.sql;
@/opt/app/oracle/11.2.0.4/base/dbhome/rdbms/admin/owminst.plb;
connect "SYSTEM"/"&&systemPassword"
@/opt/app/oracle/11.2.0.4/base/dbhome/sqlplus/admin/pupbld.sql;
connect "SYSTEM"/"&&systemPassword"
set echo on
spool sqlPlusHelp.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/sqlplus/admin/help/hlpbld.sql helpus.sql;
spool off
spool off

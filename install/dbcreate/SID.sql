set verify off
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
@CreateDB.sql
@CreateDBFiles.sql
@CreateDBCatalog.sql
@JServer.sql
@xdb_protocol.sql
@ordinst.sql
@interMedia.sql
@apex.sql
host /opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl add database -d SID_ -o /opt/app/oracle/11.2.0.4/base/dbhome -n SID_ -a "DATA"
rem host echo "SPFILE='+DATA/SID_/spfileSID_'" > /opt/app/oracle/11.2.0.4/base/dbhome/dbs/init$ORACLE_SID.ora
@lockAccount.sql
@postDBCreation.sql

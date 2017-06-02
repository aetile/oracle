SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /opt/app/oracle/11.2.0.4/base/admin/sapphire/scripts/apex.log append
@/opt/app/oracle/11.2.0.4/base/dbhome/apex/catapx.sql change_on_install SYSAUX SYSAUX TEMP /i/ NONE;
spool off

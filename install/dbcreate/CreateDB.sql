SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool CreateDB.log append
startup nomount pfile="/opt/app/oracle/11.2.0.4/base/admin/SID_/scripts/initSID_.ora";
CREATE DATABASE "DB_NAME_"
MAXINSTANCES 32
MAXLOGHISTORY 1
MAXLOGFILES 192
MAXLOGMEMBERS 3
MAXDATAFILES 1024
DATAFILE SIZE 700M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SYSAUX DATAFILE SIZE 600M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP TEMPFILE SIZE 20M AUTOEXTEND ON NEXT  640K MAXSIZE UNLIMITED
SMALLFILE UNDO TABLESPACE "UNDOTBS1" DATAFILE SIZE 200M AUTOEXTEND ON NEXT  5120K MAXSIZE UNLIMITED
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
LOGFILE GROUP 1 '+REDO' SIZE 51200K,
GROUP 2 '+REDO' SIZE 51200K,
GROUP 3 '+REDO' SIZE 51200K
USER SYS IDENTIFIED BY "&&sysPassword" USER SYSTEM IDENTIFIED BY "&&systemPassword";
set linesize 2048;
column ctl_files NEW_VALUE ctl_files;
select concat('control_files=''', concat(replace(value, ', ', ''','''), '''')) ctl_files from v$parameter where name ='control_files';
host sed -i '/control_files=/ {$!N;d;}' /opt/app/oracle/11.2.0.4/base/admin/SID_/scripts/initSID_.ora;
host echo &ctl_files >>/opt/app/oracle/11.2.0.4/base/admin/SID_/scripts/initSID_.ora;
spool off

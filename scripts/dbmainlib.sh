#!/bin/bash
# Thanks to Tanel Poder for HTML formating in SQLplus output

DIR_SCRIPTS=/home/oracle/scripts

log_head() {
   echo > $LOG
   echo "$(date '+%d/%m/%Y (%H:%M:%S)')" | tee -a $LOG
   echo >> $LOG
}

log_tail() {
   echo >> $LOG
   echo "$(date '+%d/%m/%Y (%H:%M:%S)')" | tee -a $LOG
}

set_oraenv() {
   . $DIR_SCRIPTS/${SID}.conf
   MAIL_TMP=$DIR_SCRIPTS/tmp/mail_${PROG}_${OPTYPE}_${SID}_$(date '+%Y.%m.%d_%H.%M').html
   TMP_LOCK=$DIR_SCRIPTS/tmp/lck_${PROG}_${OPTYPE}_${SID}_$(date '+%Y.%m.%d_%H.%M')
   TMP=$DIR_SCRIPTS/tmp/${PROG}_${OPTYPE}_${SID}_$(date '+%Y.%m.%d_%H.%M').sql
   RMAN=$DIR_SCRIPTS/tmp/${PROG}_${OPTYPE}_${SID}_$(date '+%Y.%m.%d_%H.%M').rman
   log_head
   echo "Setting Oracle environment..." | tee -a $LOG
   cd $HOME
   export ORACLE_SID=$SID
   . /usr/local/bin/oraenv
   echo "done." | tee -a $LOG
   echo
}

check_user() {
# $1: User to check
# $2: reference User 
if [ $1 != $2 ]; then
 echo "You must log in as $2 user."
 exit 1
fi
}

send_mail () {
  if [ "$MONITORING" = "Y" ]; then
   $DIR_SCRIPTS/smail -d "$EMAIL" -s $SENDER -m $SMTP -b "$LABEL" -t $MAIL_TMP -f $FORMAT | tee -a $LOG
  fi
}

check_db() {
# $1: user
   OLD_MONITORING=$MONITORING
   set_oraenv
   log_head

   # Forced monitoring option
   if [ "$FORCE_MONITORING" -a "$FORCE_MONITORING" = "Y" ]; then
    MONITORING=Y
   fi

   # If user is not oracle, don't check db
   if [ $1 != oracle ]; then
    OUSER=$1
    return
   fi

   echo "Checking Database status..." | tee -a $LOG
   echo >> $LOG

   # Check if database is accepting connections
   #echo "set echo off termout off serveroutput off feedback off" > $TMP
   echo "set lines 500 pages 9999" > $TMP
   echo "select instance_name, status from v\$instance;" >> $TMP
   echo exit >> $TMP
   $ORACLE_HOME/bin/sqlplus / as sysdba @$TMP >> $LOG
   echo >> $LOG
   check_conn=`cat $LOG | grep -i error | wc -l`
   oracle_conn=`expr $check_conn`

   # Check if database is open
   check_idle=`cat $LOG | grep -i idle | wc -l`
   oracle_idle=`expr $check_idle`

   # Check if PMON is running
   check_pmon=`ps -ef | grep ${ORACLE_SID} | grep pmon | wc -l`
   oracle_pmon=`expr $check_pmon`

   # Check listener status
   LSNR_NAME=`grep LISTENER $ORACLE_HOME/network/admin/listener.ora | head -1 | cut -d '=' -f 1`
   lsnrctl status $LSNR_NAME
   oracle_lsnr=$?

   # Send alert
   if echo $ENV | grep PRD >> /dev/null; then
    MONITORING=Y
   fi
   if [ $oracle_conn -ne 0 ]; then
     if [ $oracle_pmon -lt 1 ]; then
       LABEL="[$LABEL - ALERT: DB Instance is DOWN!]"
       cat $LOG > $MAIL_TMP
       echo >> $MAIL_TMP
       ps -aef | grep pmon >> $MAIL_TMP
       send_mail
       echo "Database is DOWN. Aborting." | tee -a $LOG
     else
       EMAIL="$EMAIL"
       LABEL="[$LABEL - ALERT: DB Instance NOT AVAILABLE!]"
       cat $LOG > $MAIL_TMP
       echo >> $MAIL_TMP
       send_mail
       echo "Database not available. Aborting." | tee -a $LOG
     fi
     log_tail
     exit 2
   else
     if [ $oracle_idle -gt 0 ]; then
       LABEL="[$LABEL - ALERT: DB Instance not MOUNTED!]"
       cat $LOG > $MAIL_TMP
       echo >> $MAIL_TMP
       send_mail
       echo "Database not mounted. Aborting." | tee -a $LOG
       log_tail
       exit 2
     else
       grep $SID $LOG > $MAIL_TMP
       sed -i -r "s#[ ]+#:#g" $MAIL_TMP
       DB_STATUS=`cat $MAIL_TMP | cut -d ':' -f 2`
       case $DB_STATUS in
         MOUNT*)
           LABEL="[$LABEL - ALERT: DB Instance not OPEN!]"
           cat $LOG > $MAIL_TMP
           echo >> $MAIL_TMP
           send_mail
           echo "Database not open. Aborting." | tee -a $LOG
           log_tail
           exit 2
           ;;
         *)
           cat $LOG > $MAIL_TMP
           ;;
       esac
     fi
   fi

   if [ $oracle_lsnr -ne 0 ]; then
     LABEL="[$LABEL - WARNING: DB Listener error]"
     cat $LOG > $MAIL_TMP
     echo >> $MAIL_TMP
     lsnrctl status $LSNR_NAME >> $MAIL_TMP
     send_mail
     echo "Warning: Listener error." | tee -a $LOG
   fi

   MONITORING=$OLD_MONITORING
   echo >> $LOG
   echo > $TMP
}

set_html() {
# $1: Target SQLplus file
   echo "set lines 200 pages 9999" > $1
   echo "set termout on" >> $1
   echo "set markup HTML ON HEAD \" -" >> $1
   echo " -" >> $1
   echo "body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} -" >> $1
   echo "p {   font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} -" >> $1
   echo "     table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; -" >> $1
   echo "     padding:0px 0px 0px 0px; margin:0px 0px 0px 0px; white-space:nowrap;} -" >> $1
   echo "th {  font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; -" >> $1
   echo "     padding:0px 0px 0px 0px;} -" >> $1
   echo "h1 {  font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; -" >> $1
   echo "     border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} -" >> $1
   echo "h2 {  font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; -" >> $1
   echo "     margin-top:4pt; margin-bottom:0pt;} a {font:9pt Arial,Helvetica,sans-serif; color:#663300; -" >> $1
   echo "     background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} -" >> $1
   echo " -" >> $1
   echo "\" -" >> $1
   echo "BODY \"\" -" >> $1
   echo "TABLE \"border='1' align='center' summary='Script output'\" -" >> $1
   echo "SPOOL ON ENTMAP ON PREFORMAT OFF" >> $1
}

end_html() {
# $1: target SQLplus file
   echo "set markup html off spool off" >> $1
   #host start %SQLPATH%tmpoutput_&_connect_identifier..html
   echo "set termout on" >> $1
}

exec_query() {
# $1: SQL file
# $2: mail file
# $3: log file 
   $ORACLE_HOME/bin/sqlplus / as sysdba @$1 >> $3
   cat $3 >> $2
   echo "Done." | tee -a $3
}

check_smtp() {
# $1 SMTP socket
   SMTP=$1
   SMTP1=`echo $SMTP | cut -d ',' -f 1`
   SMTP1=`echo $SMTP1 | cut -d ':' -f 1`
   SMTP1_PORT=`echo $SMTP | cut -d ',' -f 1`
   SMTP1_PORT=`echo $SMTP1_PORT | cut -d ':' -f 2`
   SMTP2=`echo $SMTP | cut -d ',' -f 2`
   SMTP2=`echo $SMTP2 | cut -d ':' -f 1`
   SMTP2_PORT=`echo $SMTP | cut -d ',' -f 2`
   SMTP2_PORT=`echo $SMTP2_PORT | cut -d ':' -f 2`
  
   if nc -w 2 $SMTP1 $SMTP1_PORT > /dev/null; then
    SMTP="$SMTP1:$SMTP1_PORT"
   else
    if nc -w 2 $SMTP2 $SMTP2_PORT > /dev/null; then
     SMTP="$SMTP2:SMTP2_PORT"
    else
     echo "SMTP service not available. Aborting."
     exit 10
    fi
   fi
}


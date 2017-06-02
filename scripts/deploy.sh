#!/bin/bash

##########################################################################################################
#
# Deploy MRAN backup environment for a single database.
#
# Input: -d Oracle SID
#        -c Datacenter (ex: FR1)
#        -e Environment (PRD:production PRE:pre-production SBX=sandbox)
#
# Created: 21/01/2015 AET
# Modified:
#
##########################################################################################################

COMPANY=yourcompany
OUSER=oracle
DIR_SCRIPTS=/home/oracle/scripts
CRON=/etc/cron.d/$COMPANY_rman_backup
Cpath=$
Rpath=
LASTDIR=`pwd`
ARCHIVE=dbmain.tar.gz

source dbmainlib.sh

usage() {
echo "Usage: deploy.sh -d <Oracle SID> -c <Datacenter> -e <Environment>";
}

check_parms() {
   if [ ! -n $SID ]; then
    usage
    exit
   fi

   if [ ! -n $DBENV ]; then
    usage
    exit
   fi

   if [ ! -n $DATACENTER ]; then
    usage
    exit
   fi

   if [ -z $SID ]; then
    usage
    exit
   fi

   if [ -z $DBENV ]; then
    usage
    exit
   fi

   if [ -z $DATACENTER ]; then
    usage
    exit
   fi
}

unpack() {
   echo "Installing RMAN scripts..."
   tar -xvzf $ARCHIVE
   sleep 1
   mkdir -p /home/$OUSER/scripts
   mkdir -p /home/$OUSER/scripts/log
   mkdir -p /home/$OUSER/scripts/tmp
   chmod 770 /home/$OUSER/scripts

   # Copy files to target directory tree
   cp dbmainlib.sh /home/$OUSER/scripts/
   cp rmanbkp /home/$OUSER/scripts/
   cp backup_inc* /home/$OUSER/scripts/
   cp dbstats /home/$OUSER/scripts/
   cp dbperf /home/$OUSER/scripts/
   #cp dbcopy.sql /home/$OUSER/scripts/
   cp dbmon /home/$OUSER/scripts/
   cp xrebuild /home/$OUSER/scripts/
   cp tabdefrag /home/$OUSER/scripts/
   cp eminst /home/$OUSER/scripts/
   cp sendEmail /home/$OUSER/scripts/
   cp smail /home/$OUSER/scripts/
   #cp rman.cron /home/$OUSER/scripts/
   #cp dbmon.cron /home/$OUSER/scripts/
   #cp statspack.cron /home/$OUSER/scripts/
   #cp rman.conf /home/$OUSER/scripts/
   #cp logrotate.conf /home/$OUSER/scripts/
   #cp tbs.sql /home/$OUSER/scripts/
   #cp data.sql /home/$OUSER/scripts/
   #cp rman.sql /home/$OUSER/scripts/
   #cp dbcopy.sql /home/$OUSER/scripts/
   #cp sppurpkg.sql /home/$OUSER/scripts/
   #cp SID.conf /home/$OUSER/scripts/$SID.conf
   cp *.conf /home/$OUSER/scripts/
   cp *.cron /home/$OUSER/scripts/
   cp *.sql /home/$OUSER/scripts/
   ln -s $DIR_SCRIPTS/sendEmail $DIR_SCRIPTS/sendEmail.pl
   cd /home/$OUSER/scripts

   chmod -x *.conf *.cron *.sql
   chmod +x /home/$OUSER/scripts/dbmainlib.sh
   chmod +x /home/$OUSER/scripts/rmanbkp
   chmod +x /home/$OUSER/scripts/backup_inc*
   chmod +x /home/$OUSER/scripts/dbstats
   chmod +x /home/$OUSER/scripts/dbperf
   chmod +x /home/$OUSER/scripts/dbmon
   chmod +x /home/$OUSER/scripts/xrebuild
   chmod +x /home/$OUSER/scripts/tabdefrag
   chmod +x /home/$OUSER/scripts/sendEmail
   chmod +x /home/$OUSER/scripts/smail
   chmod +x /home/$OUSER/scripts/eminst
   chown -R oracle:oinstall /home/$OUSER/scripts
}

configure() {
   # RAC instance
   CLUST_NODE=zzzzz
   i=0
   while ! grep $CLUST_NODE /etc/oratab
   do
    i=$((i+1))
    if [ $i -eq 4 ]; then
     echo "Aborting."
     exit
    fi
    echo "Please enter RAC node SID from oratab configuration file ([${SID}]):"
    read CLUST_NODE
    if [ -z $CLUST_NODE ]; then
     CLUST_NODE=$SID
    fi
   done

   # Replace cluster node name in config files
   sed -i "s#RAC_INST_#$CLUST_NODE#g" /home/$OUSER/scripts/$SID.conf

   # APP schema
   SQLCMD="su -l oracle -c \"$ORACLE_HOME/bin/sqlplus /@$CLUST_NODE\""
   DEFAULT_SCHEM=`grep APP_SCHEMA $SID.conf | cut -d '=' -f 2-`
   i=0
   while ! $SQLCMD > /dev/null 2>&1
   do
    i=$((i+1))
    if [ $i -eq 4 ]; then
     echo "Aborting."
     exit
    fi
    echo "Please enter applicative schema name and password (<schema name/<password>):"
    read SCHEM
    SQLCMD=`echo $SQLCMD | sed -i "s#/#$SCHEM#" > /dev/null 2>&1`
   done

   # Replace schema name in config file
   SCHEM=`echo $SCHEM | cut -d '/' -f 1`
   sed -i "s#SCHEM_#$SCHEM#g" /home/$OUSER/scripts/$SID.conf

   # Replace ENV in config
   ENV="$DATACENTER $DBENV"
   sed -i "s#ENV\=\"FR1 PRD\"#ENV\=\"$ENV\"#g" /home/$OUSER/scripts/$SID.conf

   # Replace SID in cron file
   sed -i "s#SID_#$SID#g" /home/$OUSER/scripts/rman.cron
}

install_smtp() {
   # SMTP server
   SMTP_DEFAULT=`grep SMTP $SID.conf | cut -d '=' -f 2-`
   #HOST=`echo $SMTP_DEFAULT | cut -d ':' -f 1-`
   #PORT=`echo $SMTP_DEFAULT | cut -d ':' -f 2-`
   SMTP=
   i=0
   while ! ping -c 1 $SMTP_HOST > /dev/null 2>&1
   do
    i=$((i+1))
    if [ $i -eq 4 ]; then
     echo "Aborting."
     exit
    fi
   echo "Please enter SMTP server socket for email notifications [$SMTP_DEFAULT]:"
   read SMTP
    if [ -z $SMTP ]; then
     SMTP=$SMTP_DEFAULT
    fi
    SMTP_HOST=`echo $SMTP | cut -d ':' -f 1`
   done

   # Replace SMTP socket in config file
   if [ $SMTP != $SMTP_DEFAULT ];then
    sed -i "s#$SMTP_DEFAULT#$SMTP#g" /home/$OUSER/scripts/$SID.conf
   fi
}

install_rman() {
   # Check Backup path
   Rpath=`df | grep backup/oracle | awk '{ print $5}'`
   Dpath=`grep -m 1 RMAN_DISK $SID.conf | cut -d '=' -f 2-`

   i=0
   while [ ! -d $Cpath ]
   do
    i=$((i+1))
    if [ $i -eq 4 ]; then
     echo "Aborting."
     exit
    fi
    echo "Please enter a valid path for RMAN backup files [$Rpath]:"
    read Cpath
    Cpath=$Cpath/
    if [ $Cpath = / ]; then
     Cpath=$Rpath
    fi
   done

   # Replace file path in config
   if [ $Cpath != $Rpath ];then
    sed -i "s#$Rpath#$Cpath#g" /home/$OUSER/scripts/$SID.conf
   fi
   sed -i "s#$Dpath#$Cpath#g" /home/$OUSER/scripts/$SID.conf
   sed -i "s#RMAN_PATH_#$Cpath#g" /home/$OUSER/scripts/rman.conf
   sed -i "s#SID_#$SID#g" /home/$OUSER/scripts/rman.conf

   # Load RMAN config
   su -l oracle -c "rman target / @rman.conf"
}

install_cron() {
   CRON=/etc/cron.d/$COMPANY_rman_backup_$SID
   echo "Current crontab contents:"
   echo
   sleep 1
   cat /etc/cron.d/*
   echo
   echo "RMAN backup jobs to be installed:"
   cat rman.cron
   echo
   echo "Monitoring jobs to be installed:"
   cat dbmon.cron
   echo
   echo "Install cron jobs? (y/n)"
   read key

   case $key in
    y|Y)
     echo "Installing RMAN cron jobs..."
     mv rman.cron $CRON
     mv dbmon.cron /etc/cron.d/$COMPANY_dbmon_$SID
     sed -i "s#SID_#$SID#g" $CRON
     sed -i "s#SID_#$SID#g" /etc/cron.d/$COMPANY_dbmon_$SID

     chown root:root $CRON
     chown root:root /etc/cron.d/$COMPANY_dbmon_$SID
     /etc/init.d/crond restart
     ;;
    *)
     echo "Cron jobs not installed."
     ;;
   esac
}

install_statspack() {
   echo "Install Statspack? (y/n)"
   read key

   case $key in
    y|Y)
     echo "Installing Statspack..."
     sleep 1

     i=0
     perf_days=0
     while [ ! $perf_days -gt 0 ]; do
      i=$((i+1))
      if [ $i -eq 4 ]; then
       echo "Aborting."
       exit
      fi
      echo "Enter snapshot retention in days [30]:"
      read perf_days
      if [ -z $perf_days ]; then
       perf_days=30
      fi
     done
     sed -i "s#PERF_DAYS_#$perf_days#g" /home/oracle/scripts/$SID.conf

     i=0
     snap_level=-1
     while [ ! $snap_level -ge 0 ]; do
      i=$((i+1))
      if [ $i -eq 4 ]; then
       echo "Aborting."
       exit
      fi
      echo "Enter snapshot collection level [7]:"
      read snap_level
      if [ -z $snap_level ]; then
       snap_level=7
      fi
     done
     sed -i "s#SNAP_LEVEL_#$snap_level#g" /home/oracle/scripts/$SID.conf
     sed -i "s#SID_#$SID#g" /home/$OUSER/scripts/statspack.cron

     su -l oracle -c "sqlplus / as sysdba @?/rdbms/admin/spcreate.sql"
     su -l oracle -c "sqlplus / as sysdba @?/rdbms/admin/spup11201.sql"
     su -l oracle -c "sqlplus / as sysdba @sppurpkg.sql"
     mv statspack.cron /etc/cron.d/$COMPANY_statspack_$SID
     chown root:root /etc/cron.d/$COMPANY_statspack_$SID
     /etc/init.d/crond restart

     echo "Initializing Statspack..."
     su -l oracle -c "/home/$OUSER/scripts/dbperf -d $SID -s -l $snap_level"
     echo "Done."
     ;;
    *)
     echo "Statspack not installed."
     ;;
   esac
   echo
}

clean_up() {
   echo "Cleaning install files..."
   sleep 1
   #rm -f deploy.sh
   cd $LASTDIR
   rm -f sendEmail smail SID.conf backup_inc* dbstats dbcopy.sql xrebuild tabdefrag rman* dbmon* dbperf tbs.sql data.sql sppurpkg.sql eminst dbmain* statspack*
   echo "Done."
}

############
# MAIN
############

# Argument parsing
while getopts :d:c:e: arg
do
case $arg in
  d)
    SID=$OPTARG
    ;;
  c)
    DATACENTER=$OPTARG
    ;;
  e)
    DBENV=$OPTARG
    ;;
  \?)
    usage
    exit
    ;;
   :)
    echo "Option $OPTARG requires an argument."
    exit
    ;;
esac
done

# Check User
check_user $USER root

# Check input parameters
check_parms

# Safely create directory tree and unpack files
unpack

# Basic configuration
configure

# configure SMTP
install_smtp

# Configure RMAN
install_rman

# Install crontab jobs
install_cron

# Statspack install
install_statspack

# Clean up
clean_up

exit


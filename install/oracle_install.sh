#!/bin/sh

WORKDIR=/root
OPTYPE=GRID
RAC=N
DB=N
DATA=N
ASM=N
GRID=N
NETWORK=N
ORACLE_BASE=/opt/app/oracle/11.2.0.4/base
INSTALL_DIR=/opt/app/oracle/oracle_install
GRID_INST=$INSTALL_DIR/grid
GRID_HOME=$ORACLE_BASE/grid
RAC_HOME=/opt/app/oracle/11.2.0.4/grid
ORA_INV=/home/oracle/oraInventory
DB_INST=$INSTALL_DIR/database
DB_HOME=$ORACLE_BASE/dbhome
DB_PORT=1521
ORA_OCR=ORA_OCR
ORA_DATA=ORA_DATA_01
ORA_REDO=ORA_REDO_01
OCR_DEV=kfr_tpr_db_ocr
DATA_DEV=kfr_tpr_db_data_1
REDO_DEV=kfr_tpr_db_redo
V_HOSTNAME=`hostname -s`
XCODE=0
TMP_FILE=/root/oracle_install.tmp

usage() {
   echo "Usage: oracle_install.sh -i <install_type> -s <DB_name> [-n <node_list>]"
}

check_parms() {
   if [ ! -n "$SID" ]; then
    usage
    exit 1
   fi

   if [ -z "$SID" ]; then
    usage
    exit 1
   fi

   case $OPTYPE in
     RAC|rac)
       if [ ! -n "$NLIST" ]; then
         echo "RAC install requires a node list (-n option)."
         usage
         exit 1
       fi

       if [ -z "$NLIST" ]; then
         echo "RAC install requires a node list (-n option)."
         usage
         exit 1
       fi
       ;;
     *)
       ;;
   esac
}

prepare_install() {
   RSP_FILE="grid.rsp"
   if [ $NLIST ]; then
     GRID_HOME=$RAC_HOME
     RSP_FILE="grid_rac.rsp"
   fi

   # Test if response file exists
   if [ "$GRID" = "Y" ]; then
     if [ ! -f $GRID_INST/$RSP_FILE ]; then
       echo "GI response file is missing. Aborting."
       exit 11
     fi
   fi

   if [ "$DB" = "Y" ]; then
     if [ ! -f $DB_INST/db.rsp ]; then
       echo "DBMS response file is missing. Aborting."
       exit 12
     fi
   fi

   if [ $NLIST ] && [ "$GRID" = "Y" ]; then
     echo $NLIST > $TMP_FILE
     sed -i "s#,#\n#g" $TMP_FILE
     for node in `cat $TMP_FILE`
     do
       ssh $node "mkdir -p /opt/app/oracle/11.2.0.4"
       ssh $node "mkdir -p $ORACLE_BASE"
       ssh $node "mkdir -p $GRID_HOME"
       ssh $node "mkdir -p $DB_HOME"
       ssh $node "chown -R oracle:oinstall /opt/app/oracle/11.2.0.4"

       # required packages
       ssh $node "yum install $GRID_INST/rpm/cvuqdisk-1.0.9-1.rpm -y"
       ssh $node "yum install redhat-lsb-core -y"
     done
   else
     mkdir -p /opt/app/oracle/11.2.0.4
     mkdir -p $ORACLE_BASE
     mkdir -p $GRID_HOME
     mkdir -p $DB_HOME
     #mkdir -p $ORACLE_BASE/admin
     #mkdir -p $ORACLE_BASE/admin/$SID
     #mkdir -p $ORACLE_BASE/admin/$SID/scripts
     chown -R oracle:oinstall /opt/app/oracle/11.2.0.4
   fi
   mkdir -p $ORACLE_BASE/admin
   mkdir -p $ORACLE_BASE/admin/$SID
   mkdir -p $ORACLE_BASE/admin/$SID/scripts
   chown -R oracle:oinstall /opt/app/oracle/11.2.0.4

   # Temp files clean-up
   [ -d /var/tmp.oracle ] && rm -rf /var/tmp/.oracle
   rm -rf /tmp/Ora*
   #rm -rf $ORA_INV

   # DB creation files
   DB_NAME=`echo $SID | cut -c1-8`
   if [ "$DATA" = "Y" ]; then
     cp -f $ORACLE_BASE/admin/$SID/scripts/init.ora $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
     if [ -f $ORACLE_BASE/admin/$SID/scripts/SID.sh ]; then
       mv $ORACLE_BASE/admin/$SID/scripts/SID.sh $ORACLE_BASE/admin/$SID/scripts/$SID.sh
     fi
     chmod +x $ORACLE_BASE/admin/$SID/scripts/$SID.sh

     if [ -f $ORACLE_BASE/admin/$SID/scripts/SID.sql ]; then
       mv $ORACLE_BASE/admin/$SID/scripts/SID.sql $ORACLE_BASE/admin/$SID/scripts/$SID.sql
     fi

     # RAC specific
     if [ $NLIST ]; then
       if ! grep "${SID}1.instance_number=1" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}1.instance_number=1" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
       if ! grep "${SID}1.thread=1" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}1.thread=1" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
       if ! grep "${SID}1.undo_tablespace=UNDOTBS1" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}1.undo_tablespace=UNDOTBS1" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
     else
       if ! grep "undo_tablespace=UNDOTBS1" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "undo_tablespace=UNDOTBS1" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
     fi

     # +1 UNDO tablespace +3 REDO groups per additional cluster node
     echo $NLIST > $TMP_FILE
     sed -i "s#,#\n#g" $TMP_FILE
     i=1
     for node in `grep -v $(hostname -s) $TMP_FILE`
     do
       i=$((i+1))
       redo_1=$((i+2))
       redo_2=$((i+3))
       redo_3=$((i+4))
       SQL_UNDO="CREATE SMALLFILE UNDO TABLESPACE UNDOTBS${i} DATAFILE SIZE 200M AUTOEXTEND ON NEXT  5120K MAXSIZE UNLIMITED;"
       SQL_REDO="ALTER DATABASE ADD LOGFILE THREAD $i GROUP $redo_1 SIZE 51200K, GROUP $redo_2 SIZE 51200K, GROUP $redo_3  SIZE 51200K;"
       SQL_THREAD="ALTER DATABASE ENABLE PUBLIC THREAD $i;"
       SQL_VIEWS="@CreateClustDBViews.sql"
       SQL_LSNR="host echo remote_listener=$SID-scan:$DB_PORT >>/opt/app/oracle/11.2.0.4/base/admin/$SID/scripts/init$SID.ora;"
       SQL_CLUST="host echo cluster_database=true >>/opt/app/oracle/11.2.0.4/base/admin/$SID/scripts/init$SID.ora;"

       # Additional UNDO tbs
       awk -v var="$SQL_UNDO" '/CREATE SMALLFILE TABLESPACE/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/CreateDBFiles.sql > $TMP_FILE
       cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/CreateDBFiles.sql

       # Additional REDO groups
       awk -v var="$SQL_REDO" '/utl_recomp_end/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql > $TMP_FILE
       cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
       awk -v var="$SQL_THREAD" '/ALTER DATABASE ADD LOGFILE/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql > $TMP_FILE
       cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql

       # Clusterware views
       awk -v var="$SQL_VIEWS" '/apex.sql/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/$SID.sql > $TMP_FILE
       if ! grep "$SQL_VIEWS" $ORACLE_BASE/admin/$SID/scripts/$SID.sql >> /dev/null; then
         cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/$SID.sql
       fi

       # Init file parameters
       if ! grep "${SID}${i}.instance_number=${i}" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}${i}.instance_number=${i}" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
       if ! grep "${SID}${i}.thread=${i}" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}${i}.thread=${i}" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
       if ! grep "${SID}${i}.undo_tablespace=UNDOTBS${i}" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora >> /dev/null; then
         echo "${SID}${i}.undo_tablespace=UNDOTBS${i}" >> $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
       fi
       awk -v var="$SQL_LSNR" '/set echo on/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql > $TMP_FILE
       cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
       awk -v var="$SQL_CLUST" '/set echo on/ { print; print var; next }1' $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql > $TMP_FILE
       cat $TMP_FILE > $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
     done

     # Update creation scripts
     sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/CreateDB.sql
     sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/CreateDB.sql
     sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
     sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
     sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
     sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/postDBCreation.sql
     sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
     sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
     sed -i "s#GRID_HOME_#$GRID_HOME#g" $ORACLE_BASE/admin/$SID/scripts/$SID.sh
     sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/$SID.sql
     sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/$SID.sql
     if [ $NLIST ]; then
       sed -i "s#DB_NAME_#$DB_NAME#g" $ORACLE_BASE/admin/$SID/scripts/CreateClustDBViews.sql
       sed -i "s#SID_#$SID#g" $ORACLE_BASE/admin/$SID/scripts/CreateClustDBViews.sql
     fi

     # DB init file: memory config parameters: default to 40% of Mem Total
     SGA=`echo "0.4*1024*$(cat /proc/meminfo | grep -i MemTotal | awk '{print $2}')" | bc | cut -d '.' -f 1`
     sed -i "s#SGA_#$SGA#g" $ORACLE_BASE/admin/$SID/scripts/init$SID.ora
     chown oracle:oinstall $ORACLE_BASE/admin/$SID/scripts/*
   fi

   # DB Software response file
   if [ "$DB" = "Y" ]; then
     sed -i "s#BASE_#$ORACLE_BASE#g" $DB_INST/db.rsp
     sed -i "s#HOME_#$DB_HOME#g" $DB_INST/db.rsp
     sed -i "s#HOST_#$V_HOSTNAME#g" $DB_INST/db.rsp
     sed -i "s#INV_#$ORA_INV#g" $DB_INST/db.rsp
     sed -i "s#CLUST_NODES_#$NLIST#g" $DB_INST/db.rsp
   fi

   # Grid Infrastructure response file
   if [ "$GRID" = "Y" ]; then
     sed -i "s#BASE_#$ORACLE_BASE#g" $GRID_INST/$RSP_FILE
     sed -i "s#HOME_#$GRID_HOME#g" $GRID_INST/$RSP_FILE
     sed -i "s#HOST_#$V_HOSTNAME#g" $GRID_INST/$RSP_FILE
     sed -i "s#INV_#$ORA_INV#g" $GRID_INST/$RSP_FILE
   fi

   # RAC configuration
   if [ $NLIST ] && [ "$GRID" = "Y" ]; then
    SCAN_NAME=$SID-scan

    # Create ASM disk for OCR
    #oracleasm deletedisk $ORA_OCR
    #oracleasm scandisks
    #oracleasm createdisk $ORA_OCR /dev/mapper/$OCR_DEV
    #echo $NLIST > $TMP_FILE
    #sed -i "s#,#\n#g" $TMP_FILE
    #for node in `cat $TMP_FILE`
    #do
    #  ssh $node "oracleasm scandisks"
    #done

    # RAC interconnect and public network configuration
    # Private network is expected to be configured on eth5 and eth6 interfaces, public network on eth1 interface, all other interfaces should be unused
    cd /etc/sysconfig/network-scripts
    ls -l ifcfg-eth* | awk '{ print $9 }' > $TMP_FILE
    cd $WORKDIR
    for iface in `cat $TMP_FILE`
    do
      ifname=`echo $iface | cut -d '-' -f 2`
      case $ifname in
        eth1)
          iftype=1
          ;;
        eth5|eth6)
          iftype=2
          ;;
        *)
          iftype=3
          ;;
      esac
      ifIP=`grep IPADDR /etc/sysconfig/network-scripts/$iface | cut -d '=' -f 2`
      ifMASK=`grep NETMASK /etc/sysconfig/network-scripts/$iface | cut -d '=' -f 2`
      ifNET=`ipcalc -n $ifIP $ifMASK | cut -d '=' -f 2`
      IF_LIST=${IF_LIST}${ifname}:${ifNET}:${iftype},
    done

    # remove the last comma
    charcount=`echo $IF_LIST | wc -m`
    charcount=$((charcount-2))
    IF_LIST=`echo $IF_LIST | cut -c1-$charcount`

    # Node list with related VIP name
    echo $NLIST > $TMP_FILE
    sed -i "s#,#\n#g" $TMP_FILE
    for node in `cat $TMP_FILE`
    do
      SCAN_LIST=${SCAN_LIST}${node}:${node}-vip,
    done

    # remove the last comma
    charcount=`echo $SCAN_LIST | wc -m`
    charcount=$((charcount-2))
    SCAN_LIST=`echo $SCAN_LIST | cut -c1-$charcount`

    # Replace patterns in response file
    sed -i "s#ORA_OCR_#$ORA_OCR#g" $GRID_INST/$RSP_FILE
    sed -i "s#SCAN_NAME_#$SCAN_NAME#g" $GRID_INST/$RSP_FILE
    sed -i "s#SCAN_PORT_#$DB_PORT#g" $GRID_INST/$RSP_FILE
    sed -i "s#CLUSTER_NAME_#$SID#g" $GRID_INST/$RSP_FILE
    sed -i "s#NODE_LIST_#$SCAN_LIST#g" $GRID_INST/$RSP_FILE
    sed -i "s#IF_LIST_#$IF_LIST#g" $GRID_INST/$RSP_FILE
   fi

   if [ "$GRID" = "Y" -o "$ASM" = "Y" ]; then
     echo
     echo "Enter ASM SYS password:"
     read SYS_PWD
     sed -i "s#SYS_PWD_#$SYS_PWD#g" $GRID_INST/$RSP_FILE

     echo
     echo "Enter ASM SNMP password:"
     read SNMP_PWD
     sed -i "s#SNMP_PWD_#$SNMP_PWD#g" $GRID_INST/$RSP_FILE
   fi

   # ASMLib config
   #/usr/sbin/oracleasm configure -i -e -u oracle -g dba -o "dm" -x "sd"
}

install_grid() {
   # Oracle Grid Infrastructure
   export ORACLE_HOME=$GRID_HOME
   export ORAENV_ASK=NO

   echo
   echo "Installing Grid Infrastructure..."
   echo

   # Response file
   RSP_FILE="grid.rsp"
   if [ $NLIST ]; then
     RSP_FILE="grid_rac.rsp"
     #NHOSTS=`echo $NLIST | sed "s#,# #g"`
     #$GRID_INST/sshsetup/sshUserSetup.sh -user oracle -hosts "$NHOSTS" -noPromptPassphrase
     su oracle -c "$GRID_INST/runcluvfy.sh stage -pre crsinst -n $NLIST -fixup -r 11gR2 -verbose" | tee /home/oracle/grid_cluvfy.log
     echo
     echo "Continue? (yes/no)"
     read CLU_OK
     case $CLU_OK in
       yes|YES)
          echo "Resuming install..."
          ;;
       *)
          exit
          ;;
     esac
     su oracle -c "$GRID_INST/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile $GRID_INST/$RSP_FILE" CRS=true
   else
     su oracle -c "$GRID_INST/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile $GRID_INST/$RSP_FILE"
   fi

   if [ $? -ne 0 ]; then
     return 10
   fi

   # Post install config
   if [ $NLIST ] && [ "$GRID" = "Y" ]; then
     echo $NLIST > $TMP_FILE
     sed -i "s#,#\n#g" $TMP_FILE
     for node in `cat $TMP_FILE`
     do
       if [ -f $ORA_INV/orainstRoot.sh ]; then
         echo
         echo "Executing $ORA_INV/orainstRoot.sh on node $node..."
         ssh $node "$ORA_INV/orainstRoot.sh"
       fi
     done
   else
     if [ -f $ORA_INV/orainstRoot.sh ]; then
       echo
       echo "Executing $ORA_INV/orainstRoot.sh ..."
       $ORA_INV/orainstRoot.sh
     fi
   fi

   #$GRID_HOME/root.sh
   if [ $NLIST ]; then
     echo $NLIST > $TMP_FILE
     sed -i "s#,#\n#g" $TMP_FILE
     for node in `cat $TMP_FILE`
     do
       echo
       echo "Executing $GRID_HOME/root.sh on node $node..."
       ssh $node "$GRID_HOME/root.sh"
     done
   else
      echo
      echo "Executing $GRID_HOME/root.sh..."
     $GRID_HOME/root.sh
   fi

   # ASM configuration
   echo
   echo "Configuring ASM..."
   echo "oracle.assistants.asm|S_ASMPASSWORD=$SYS_PWD" > $GRID_INST/cfgrsp.properties
   echo "oracle.assistants.asm|S_ASMMONITORPASSWORD=$SNMP_PWD" >> $GRID_INST/cfgrsp.properties
   if [ $NLIST ]; then
     echo "oracle.crs|S_BMCPASSWORD=" >> $GRID_INST/cfgrsp.properties
   fi
   chown oracle:oinstall $GRID_INST/cfgrsp.properties
   chmod 660 $GRID_INST/cfgrsp.properties
   $GRID_HOME/cfgtoollogs/configToolAllCommands RESPONSE_FILE=$GRID_INST/cfgrsp.properties
   rm -f $GRID_INST/cfgrsp.properties

   $GRID_HOME/bin/crs_stat -t
   return 0
}


install_asm() {
   #  export ORACLE_SID=+ASM
   # Drop and recreate ASM disks
   #su -l oracle -c "$GRID_HOME/bin/srvctl stop asm -f"

   echo
   echo "Configuring ASM..."
   echo

   if [ $NLIST ]; then
     su oracle -c "$GRID_HOME/bin/asmca -silent -createDiskGroup -diskGroupName DATA -diskList 'ORCL:$ORA_DATA' -redundancy external -sysAsmPassword $SYS_PWD -asmsnmpPassword $SNMP_PWD"
   else
     su oracle -c "$GRID_HOME/bin/asmca -silent -configureASM -sysAsmPassword $SYS_PWD -asmsnmpPassword $SNMP_PWD -diskString 'ORCL:*' -diskGroupName DATA -disk 'ORCL:*' -redundancy EXTERNAL"
   fi

   su oracle -c "$GRID_HOME/bin/asmca -silent -createDiskGroup -diskGroupName REDO -diskList 'ORCL:$ORA_REDO' -redundancy external -sysAsmPassword $SYS_PWD -asmsnmpPassword $SNMP_PWD"

   $GRID_HOME/bin/crs_stat -t
   return $?
}

install_db() {
   # Oracle DB Software
   export ORACLE_HOME=''
   echo
   echo "Installing Database software..."
   echo

   # Run Cluster Verify if cluster install
   if [ $NLIST ]; then
     # Oracle inventory bug: CRS=true not set in inventory.xml (Doc ID 1053393.1)
     echo $NLIST > $TMP_FILE
     sed -i "s#,#\n#g" $TMP_FILE
     for node in `cat $TMP_FILE`
     do
       if ! grep 'CRS="true"' $ORA_INV/ContentsXML/inventory.xml >> /dev/null; then
         ssh $node 'sed -i "s#IDX=\"1\"#IDX=\"1\" CRS=\"true\"#"' $ORA_INV/ContentsXML/inventory.xml
       fi
     done
     su oracle -c "$GRID_INST/runcluvfy.sh stage -pre dbinst -n $NLIST -verbose" | tee /home/oracle/db_cluvfy.log
     echo
     echo "Continue? (yes/no)"
     read CLU_OK
     case $CLU_OK in
       yes|YES)
          echo "Resuming install..."
          ;;
       *)
          exit
          ;;
     esac
     su oracle -c "$DB_INST/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile $DB_INST/db.rsp" CRS=true
   else
     su oracle -c "$DB_INST/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile $DB_INST/db.rsp"
   fi
   #su oracle -c "$DB_INST/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile $DB_INST/db.rsp"

   if [ $? -ne 0 ]; then
     return 20
   fi

   # Post-install config
   if [ -f $ORA_INV/orainstRoot.sh ]; then
     echo
     echo "Executing $ORA_INV/orainstRoot.sh ..."
     $ORA_INV/orainstRoot.sh
   fi

   echo
   echo "Executing $DB_HOME/root.sh ..."
   $DB_HOME/root.sh

   $GRID_HOME/bin/crs_stat -t
   return 0
}

create_db() {
   # Database creation
   #export ORACLE_HOME=$DB_HOME
   cd $ORACLE_BASE/admin/$SID/scripts

   echo
   echo "Creating Database..."
   echo

   # Test if ASM disk are mounted
   # To be done

   # RAC database: Cluster Verify check
   if [ $NLIST ]; then
     su -l oracle -c "$GRID_INST/runcluvfy.sh stage -pre dbcfg -n $NLIST -d $DB_HOME"
     echo
     echo "Continue? (yes/no)"
     read CLU_OK
     case $CLU_OK in
       yes|YES)
          echo "Resuming install..."
          ;;
       *)
          exit
          ;;
     esac
     # Create DB for cluster
     su -l oracle -c "$ORACLE_BASE/admin/$SID/scripts/$SID.sh $SID $NLIST"
   else
     # Create standalone DB
     su -l oracle -c "$ORACLE_BASE/admin/$SID/scripts/$SID.sh $SID"
   fi

   if [ $? -ne 0 ]; then
      return 30
   fi

   $GRID_HOME/bin/crs_stat -t
   return 0
}

configure_network() {
   echo
   echo "Configuring Database network..."
   echo

   [ ! -f $GRID_HOME/network/admin/listener.original ] && mv $GRID_HOME/network/admin/listener.ora $GRID_HOME/network/admin/listener.ora.original
   [ ! -f $GRID_HOME/network/admin/tnsnames.ora.original ] && mv $GRID_HOME/network/admin/tnsnames.ora $GRID_HOME/network/admin/tnsnames.ora.original

   if [ $NLIST ]; then
     #LSNR_IP=$SID-scan
     su -l oracle -c "$GRID_HOME/bin/srvctl add listener"
     su -l oracle -c "$GRID_HOME/bin/srvctl start listener"
   else
     LSNR_IP=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eth1 | cut -d '=' -f 2`
     LSNR=$GRID_HOME/network/admin/listener.ora
     echo "LISTENER =" > $LSNR
     echo "  (DESCRIPTION_LIST =" >> $LSNR
     echo "    (DESCRIPTION =" >> $LSNR
     echo "      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC$DB_PORT))" >> $LSNR
     echo "      (ADDRESS = (PROTOCOL = TCP)(HOST = $LSNR_IP)(PORT = $DB_PORT))" >> $LSNR
     echo "    )" >> $LSNR
     echo "  )" >> $LSNR
     echo "SID_LIST_LISTENER=" >> $LSNR
     echo "  (SID_LIST=" >> $LSNR
     echo "    (SID_DESC=" >> $LSNR
     echo "      (GLOBAL_DBNAME=$SID)" >> $LSNR
     echo "      (ORACLE_HOME=$DB_HOME)" >> $LSNR
     echo "      (SID_NAME=$SID))" >> $LSNR
     echo "  )" >> $LSNR

     TNS=$GRID_HOME/network/admin/tnsnames.ora
     echo "$SID =" > $TNS
     echo "  (DESCRIPTION =" >> $TNS
     echo "   (ADDRESS_LIST =" >> $TNS
     echo "      (ADDRESS = (PROTOCOL = TCP)(HOST = $LSNR_IP)(PORT = $DB_PORT))" >> $TNS
     echo "    )" >> $TNS
     echo "    (CONNECT_DATA =" >> $TNS
     echo "      (SERVER = DEDICATED)" >> $TNS
     echo "      (SERVICE_NAME = $SID)" >> $TNS
     echo "    )" >> $TNS
     echo "  )" >> $TNS

     cp $GRID_HOME/network/admin/listener.ora $DB_HOME/network/admin/listener.ora
     cp $GRID_HOME/network/admin/tnsnames.ora $DB_HOME/network/admin/tnsnames.ora
     $GRID_HOME/bin/srvctl stop listener
     $GRID_HOME/bin/srvctl remove listener
     $GRID_HOME/bin/srvctl add listener
     $GRID_HOME/bin/srvctl start listener
   fi
}


#########
# MAIN #

# Argument parsing
while getopts :s:e:i:n:h: arg
   do
   case $arg in
     i)
       OPTYPE=$OPTARG
       ;;
     s)
       SID=$OPTARG
       ;;
     n)
       NLIST="$OPTARG"
       ;;
     \?)
       echo $arg
       usage
       exit 1
       ;;
     :)
       echo "Option $OPTARG requires an argument."
       exit 1
       ;;
   esac
done

# Parameters
check_parms

#
case $OPTYPE in
   ALL|all)
     ASM=Y
     DB=Y
     DATA=Y
     GRID=Y
     NETWORK=Y
     ;;
   RAC|rac)
     RAC=Y
     GRID=Y
     ASM=Y
     DB=Y
     NET=Y
     ;;
   ASM|asm)
     ASM=Y
     ;;
   GRID|grid)
     GRID=Y
     ;;
   NET|net)
     NETWORK=Y
     ;;
   DBS|dbs)
     DB=Y
     ;;
   DATA|data)
     DATA=Y
     ;;
   *)
    echo "Invalid option: $OPTARG."
    exit 1
    ;;
esac

# Preinstall
prepare_install

# Install Grid Infrastructure
if [ "$GRID" = "Y" ]; then
  install_grid
  XCODE=$?

  if [ $XCODE -ne 0 ]; then
    echo "Grid Infrastructure install failed with error code $XCODE."
    exit $XCODE
  fi
fi

# Install ASM
if [ "$ASM" = "Y" ]; then
  install_asm
  XCODE=$?

  if [ $XCODE -ne 0 ]; then
    echo "ASM install failed with error code $XCODE."
    exit $XCODE
  fi
fi

# Install DB Software
if [ "$DB" = "Y" ]; then
  install_db
  XCODE=$?

  if [ $XCODE -ne 0 ]; then
    echo "DB Software install failed with error code $XCODE."
    exit $XCODE
  fi
fi

# Configure DB network
if [ "$NETWORK" = "Y" ]; then
  configure_network
fi

# Create DB
if [ "$DATA" = "Y" ]; then
  create_db
  XCODE=$?

  if [ $XCODE -ne 0 ]; then
    echo "$SID database creation failed with error code $XCODE."
    exit $XCODE
  fi
fi

if [ $XCODE -ne 0 ]; then
  echo "DB network configuration error $XCODE."
fi

# cleanup and exit
rm -f $TMP_FILE
exit $XCODE

#!/bin/sh

OLD_UMASK=`umask`
umask 0027

# Create audit files destinations 
if [ $2 ]; then
  echo $2 > nodelist.txt
  sed -i "s#,#\n#g" nodelist.txt
  for node in `cat nodelist.txt`
  do
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/admin"
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1"
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/adump"
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/dpdump"
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/pfile"
    ssh $node "mkdir -p /opt/app/oracle/11.2.0.4/base/cfgtoollogs/dbca/$1"
  done
else
  mkdir -p /opt/app/oracle/11.2.0.4/base/admin
  mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1
  mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/adump
  mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/dpdump
  mkdir -p /opt/app/oracle/11.2.0.4/base/admin/$1/pfile
  mkdir -p /opt/app/oracle/11.2.0.4/base/cfgtoollogs/dbca/$1
fi
umask ${OLD_UMASK}

# Update oratab
export ORACLE_HOME=/opt/app/oracle/11.2.0.4/base/dbhome
if [ $2 ]; then
  export ORACLE_SID=${1}1
  i=0
  echo $2 > nodelist.txt
  sed -i "s#,#\n#g" nodelist.txt
  for node in `cat nodelist.txt`
  do
    i=$((i+1))
    ssh $node "if ! grep "$1${i}" /etc/oratab; then echo "${1}${i}:$ORACLE_HOME:Y" >> /etc/oratab; fi"
  done
else
  export ORACLE_SID=$1
  if ! grep $1 /etc/oratab; then
    echo "$1:$ORACLE_HOME:Y" >> /etc/oratab
  fi
fi
PATH=$ORACLE_HOME/bin:$PATH; export PATH

# Add GI services
cd /opt/app/oracle/11.2.0.4/base/admin/$1/scripts
/opt/app/oracle/11.2.0.4/base/dbhome/bin/orapwd file=/opt/app/oracle/11.2.0.4/base/dbhome/dbs/orapw$ORACLE_SID force=y
GRID_HOME_/bin/setasmgidwrap o=/opt/app/oracle/11.2.0.4/base/dbhome/bin/oracle
/opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl add database -d $1 -o /opt/app/oracle/11.2.0.4/base/dbhome -n $1 -p +DATA/$1/spfile$1.ora -a "DATA"
if [ $2 ]; then
  i=0
  echo $2 > nodelist.txt
  sed -i "s#,#\n#g" nodelist.txt
  for node in `cat nodelist.txt`
  do
    i=$((i+1))
    /opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl add instance -d $1 -i $1${i} -n $node
  done
fi

# Create database
/opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl disable database -d $1
/opt/app/oracle/11.2.0.4/base/dbhome/bin/srvctl stop database -d $1
/opt/app/oracle/11.2.0.4/base/dbhome/bin/sqlplus /nolog @$1.sql


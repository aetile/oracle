#!/bin/sh

EXIT_CODE=0
DEBUG=0
RAC=N
ASM=Y
ORA_DB_VERSION=11.2.0.4
WORK_DIR=/root
COMPANY=yourcompany
CLOUD=cloud.yourcompany.org
RPM_REPO=/opt/repo

# config
RHEL5_YUM_DIR=$RPM_REPO/OS/RHEL/5/os/x86_64/Server
RHEL6_YUM_DIR=$RPM_REPO/OS/RHEL/6/os/x86_64/Packages

CENTOS5_YUM_DIR=$RPM_REPO/OS/RHEL/5/os/x86_64/Server
CENTOS6_YUM_DIR=$RPM_REPO/OS/RHEL/6/os/x86_64/Packages

RHEL5_DISTRO_URL=http://$CLOUD/OS/RHEL/5/os/x86_64/Server
#RHEL6_DISTRO_URL=http://$CLOUD/OS/RHEL/6/os/x86_64/Packages
RHEL6_DISTRO_URL=$RPM_REPO/OS/RHEL/6/os/x86_64/Packages

CENTOS5_DISTRO_URL=http://$CLOUD/OS/CentOS/5/os/x86_64/Server
CENTOS6_DISTRO_URL=http://$CLOUD/OS/CentOS/6/os/x86_64/Packages

#TF_DISTRO_URL=http://$CLOUD/TF
TF_DISTRO_URL=$RPM_REPO/TF
#DB_DISTRO_URL=http://$CLOUD/DB
DB_DISTRO_URL=$RPM_REPO/DB


SMB_CLIENT_PACKAGES_RHEL5="libsmbclient-3.0.33-3.39.el5_8.x86_64.rpm
                     samba-common-3.0.33-3.39.el5_8.x86_64.rpm
                     samba-client-3.0.33-3.39.el5_8.x86_64.rpm
                     "
SMB_CLIENT_PACKAGES_CENTOS5="libsmbclient samba-common samba-client"
SMB_CLIENT_PACKAGES_RHEL6="keyutils-1.4-5.el6.x86_64.rpm
                           libtalloc-2.0.7-2.el6.x86_64.rpm
                           libtdb-1.2.10-1.el6.x86_64.rpm
                           libtevent-0.9.18-3.el6.x86_64.rpm
                           samba-common-3.6.23-12.el6.x86_64.rpm
                           samba-winbind-3.6.23-12.el6.x86_64.rpm
                           samba-winbind-clients-3.6.23-12.el6.x86_64.rpm
                           cifs-utils-4.8.1-19.el6.x86_64.rpm
                           "

SMB_CLIENT_PACKAGES_CENTOS6="cifs-utils"

ORA_ASM_PACKAGES_RHEL5="oracleasm-support-2.1.4-1.el5.x86_64.rpm
                  oracleasm-2.6.18-348.el5-2.0.5-1.el5.x86_64.rpm
                  oracleasmlib-2.0.4-1.el5.x86_64.rpm
                  "
ORA_ASM_PACKAGES_CENTOS5=$ORA_ASM_PACKAGES_RHEL5

ORA_ASM_PACKAGES_RHEL6="oracleasmlib-2.0.4-1.el6.x86_64.rpm
                        oracleasm-support-2.1.8-1.el6.x86_64.rpm
                        "
ORA_ASM_PACKAGES_CENTOS6=$ORA_ASM_PACKAGES_RHEL6

ORA_DEP_PACKAGES_NODEPS_RHEL5="elfutils-libelf-devel-0.137-3.el5.x86_64.rpm
                         elfutils-libelf-devel-static-0.137-3.el5.x86_64.rpm
                        "
ORA_DEP_PACKAGES_NODEPS_RHEL6="elfutils-libelf-0.158-3.2.el6.x86_64.rpm
                         elfutils-libelf-devel-0.158-3.2.el6.x86_64.rpm
                        "
ORA_DEP_PACKAGES_NODEPS_CENTOS5="elfutils-libelf-devel elfutils-libelf-devel-static"
#ORA_DEP_PACKAGES_NODEPS_CENTOS6="elfutils-libelf-devel elfutils-libelf-devel-static"

ORA_DEP_PACKAGES_RHEL5="libXt-1.0.2-3.2.el5.x86_64.rpm
                  libXmu-1.0.2-5.x86_64.rpm
                  libXpm-3.5.5-3.x86_64.rpm
                  libXaw-1.0.2-8.1.x86_64.rpm
                  libXtst-1.0.1-3.1.x86_64.rpm
                  libXv-1.0.1-4.1.x86_64.rpm
                  libXxf86dga-1.0.1-3.1.x86_64.rpm
                  libXxf86misc-1.0.1-3.1.x86_64.rpm
                  libdmx-1.0.2-3.1.x86_64.rpm
                  libfontenc-1.0.2-2.2.el5.x86_64.rpm
                  libxkbfile-1.0.3-3.1.x86_64.rpm
                  xorg-x11-xauth-1.0.1-2.1.x86_64.rpm
                  libXxf86vm-1.0.1-3.1.x86_64.rpm
                  libdrm-2.0.2-1.1.x86_64.rpm
                  mesa-libGL-6.5.1-7.10.el5.x86_64.rpm
                  xorg-x11-utils-7.1-2.fc6.x86_64.rpm
                  xorg-x11-apps-7.1-4.0.1.el5.x86_64.rpm
                  libstdc++-devel-4.1.2-54.el5.x86_64.rpm
                  cpp-4.1.2-54.el5.x86_64.rpm
                  kernel-headers-2.6.18-348.el5.x86_64.rpm
                  glibc-headers-2.5-107.x86_64.rpm
                  glibc-devel-2.5-107.x86_64.rpm
                  gcc-4.1.2-54.el5.x86_64.rpm
                  gcc-c++-4.1.2-54.el5.x86_64.rpm
                  libaio-devel-0.3.106-5.x86_64.rpm
                  sysstat-7.0.2-12.el5.x86_64.rpm
                  compat-libstdc++-33-3.2.3-61.x86_64.rpm
                  "

ORA_DEP_PACKAGES_RHEL6="binutils-2.20.51.0.2-5.42.el6.x86_64.rpm
                  gcc-4.4.7-11.el6.x86_64.rpm
                  gcc-c++-4.4.7-11.el6.x86_64.rpm
                  glibc-2.12-1.149.el6.i686.rpm
                  glibc-2.12-1.149.el6.x86_64.rpm
                  glibc-devel-2.12-1.149.el6.i686.rpm
                  glibc-devel-2.12-1.149.el6.x86_64.rpm
                  libgcc-4.4.7-11.el6.i686.rpm
                  libgcc-4.4.7-11.el6.x86_64.rpm
                  libstdc++-4.4.7-11.el6.i686.rpm
                  libstdc++-4.4.7-11.el6.x86_64.rpm
                  libstdc++-devel-4.4.7-11.el6.i686.rpm
                  libstdc++-devel-4.4.7-11.el6.x86_64.rpm
                  libaio-0.3.107-10.el6.i686.rpm
                  libaio-0.3.107-10.el6.x86_64.rpm
                  libaio-devel-0.3.107-10.el6.i686.rpm
                  libaio-devel-0.3.107-10.el6.x86_64.rpm
                  compat-libcap1-1.10-1.x86_64.rpm
                  compat-libstdc++-33-3.2.3-69.el6.i686.rpm
                  compat-libstdc++-33-3.2.3-69.el6.x86_64.rpm
                  ksh-20120801-21.el6.x86_64.rpm
                  make-3.81-20.el6.x86_64.rpm
                  sysstat-9.0.4-27.el6.x86_64.rpm
                  xorg-x11-apps-7.7-6.el6.x86_64.rpm
                  xorg-x11-xauth-1.0.2-7.1.el6.x86_64.rpm
                  xorg-x11-utils-7.5-6.el6.x86_64.rpm
                  "
ORA_DISTRO_PACKAGES="p13390677_112040_Linux-x86-64_1of7.zip
                    p13390677_112040_Linux-x86-64_2of7.zip
                    p13390677_112040_Linux-x86-64_3of7.zip
                    p13390677_112040_Linux-x86-64_4of7.zip
                    p13390677_112040_Linux-x86-64_5of7.zip
                    p13390677_112040_Linux-x86-64_6of7.zip
                    p13390677_112040_Linux-x86-64_7of7.zip
                    p17478514_112040_Linux-x86-64.zip
                    "

#
# Internal variables
#
HOSTNAME_LWR=`hostname -s`

OS_PLATFORM=unknown
OS_RELEASE=unknown
OS_VERSION=unknown
OS_DESCRIPTION=unknown
OS_ARCH=unknown

#
# Functions
#

dump_env() {
  echo "User:"
  echo `whoami`
  echo "Home directory:"
  echo ~
  echo "Working directory:"
  pwd
  echo "Environment:"
  set
}

usage_help() {
  echo "Usage: $0 -s|--sid db_sid_name [-R|--rac] [ -N|--noasm] [-v|--verbose]"
}

identify_os() {

  if [ -f /etc/centos-release ] ; then
    OS_DESC_FILE=/etc/centos-release
    OS_PLATFORM=CentOS
    else if [ -f /etc/redhat-release ] ; then
      OS_DESC_FILE=/etc/redhat-release
      OS_PLATFORM=RHEL
    fi
  fi

  case $OS_PLATFORM in
    CentOS)
      OS_VERSION=$(cat $OS_DESC_FILE | awk  {'print $3;'})
      OS_RELEASE=$(echo $OS_VERSION | awk -F . {'print $1;'})
      OS_DESCRIPTION=$(cat $OS_DESC_FILE)
    ;;
    RHEL)
      OS_VERSION=$(cat $OS_DESC_FILE | awk  {'print $7;'})
      OS_RELEASE=$(echo $OS_VERSION | awk -F . {'print $1;'})
      OS_DESCRIPTION=$(cat $OS_DESC_FILE)
    ;;
    *)
      OS_PLATFORM=unknown
    ;;
  esac

  OS_PLATFORM_UPR=`echo $OS_PLATFORM | awk '{ print toupper($0) }'`
  OS_PLATFORM_LWR=`echo $OS_PLATFORM | awk '{ print tolower($0) }'`


  # if HOSTTYPE is defined
  [ ! -z "$HOSTTYPE" ] && OS_ARCH=$HOSTTYPE

}


install_packages_rpm() {
# $1 -- repository URL
# $2 -- list of packages to install

 local src_url=$1
 local arg=("$@")

 YUM_DIR=${OS_PLATFORM_UPR}${OS_RELEASE}_YUM_DIR
 #cd ${!YUM_DIR}

 for ((i=1;i<$#;i++)); do {
   #rpm -ivh $src_url/${arg[i]}
   # AET 06/07/2015 - localinstall with YUM auto resolves package dependencies
   yum localinstall $src_url/${arg[i]} -y
  }
 done;

 #cd $WORK_DIR
}

install_packages_rpm_nodeps() {
# $1 -- repository URL
# $2 -- list of packages to install

 local src_url=$1
 local arg=("$@")

 for ((i=1;i<$#;i++)); do {
   rpm -ivh --nodeps $src_url/${arg[i]}
  }
 done;
}

mount_sw_depot() {

  # RPM needed to mount CIFS
  yum install cifs-utils -y
  yum install nfs-utils -y

  # User rights
  useradd -u 1050 sw_depot

  OS_DISTRO_URL=${OS_PLATFORM_UPR}${OS_RELEASE}_DISTRO_URL
  PKG_LIST=SMB_CLIENT_PACKAGES_${OS_PLATFORM_UPR}${OS_RELEASE}

  case $OS_PLATFORM_UPR in
    RHEL)
      install_packages_rpm_nodeps ${!OS_DISTRO_URL} ${!PKG_LIST}
    ;;
    CENTOS)
      echo install_packages_yum ${!OS_DISTRO_URL} ${!PKG_LIST}
    ;;
    *)
      exit_on_error "unsupported OS platform: $OS_PLATFORM_UPR"
    ;;
  esac

  if ! mount | grep sw_depot ; then
    mount $RPM_REPO
  fi
  #if ! mount | grep "sw_depot/RW_area" ; then
  #  mount $RPM_REPO/RW_area
  #fi
}


create_filesystems() {

  if ! lvs | grep lv_app ;then
   lvcreate -L 2G -n lv_app vg01
   mkfs.ext4 /dev/vg01/lv_app
  fi

  if ! lvs | grep lv_yourcompany ;then
   lvcreate -L 1G -n lv_yourcompany vg01
   mkfs.ext4 /dev/vg01/lv_yourcompany
  fi

  if ! lvs | grep lv_logs ;then
   lvcreate -L 3G -n lv_logs vg02
   mkfs.ext4 /dev/vg02/lv_logs
  fi

  if ! lvs | grep lv_app_oracle ;then
   lvcreate -L 32G -n lv_app_oracle vg02
   mkfs.ext4 /dev/vg02/lv_app_oracle
  fi

  if ! lvs | grep lv_backup ;then
   lvcreate -L 10G -n lv_backup vg02
   mkfs.ext4 /dev/vg02/lv_backup
  fi

  if ! lvs | grep lv_backup_oracle ;then
   lvcreate -L 5G -n lv_backup_oracle vg02
   mkfs.ext4 /dev/vg02/lv_backup_oracle
  fi

  if [ ! -f /etc/fstab.original ]; then
    cp /etc/fstab /etc/fstab.original
  fi

  cat /etc/fstab.original > /etc/fstab
  cat >> /etc/fstab << EOF

/dev/vg01/lv_app        /opt/app                ext4    defaults        1 2
/dev/vg02/lv_app_oracle /opt/app/oracle         ext4    defaults        1 2

/dev/vg01/lv_yourcompany     /opt/yourcompany             ext4    defaults        1 2
/dev/vg02/lv_logs       /opt/yourcompany/logs        ext4    defaults        1 2
/dev/vg02/lv_backup     /opt/yourcompany/backup      ext4    defaults        1 2
/dev/vg02/lv_backup_oracle /opt/yourcompany/backup/oracle      ext4    defaults        1 2

EOF

mkdir /opt/app
  mount /opt/app
  mkdir /opt/app/oracle
  mount /opt/app/oracle
  mkdir /opt/app/oracle/$ORA_DB_VERSION/
  mkdir /opt/app/oracle/$ORA_DB_VERSION/base
  mkdir /opt/app/oracle/$ORA_DB_VERSION/base/dbhome
  mkdir /opt/app/oracle/$ORA_DB_VERSION/base/grid
  chown -R oracle:dba /opt/app/oracle

  mkdir /opt/yourcompany
  mount /opt/yourcompany
  mkdir /opt/yourcompany/backup
  mount /opt/yourcompany/backup
  mkdir /opt/yourcompany/backup/oracle
  mount /opt/yourcompany/backup/oracle
  mkdir /opt/yourcompany/logs
  mount /opt/yourcompany/logs
}
#
# Oracle install preparation starts here
#

create_oracle_environment() {
  /usr/sbin/groupadd -g 200 dba
  /usr/sbin/groupadd -g 201 oinstall

  mkdir -p /home/oracle
  chgrp dba /home/oracle
  useradd  -u 200 -g oinstall -c "Oracle software owner" -G dba -s /bin/bash -d /home/oracle oracle
  chown oracle:dba /home/oracle
  echo unset JAVA_HOME >> /home/oracle/.bash_profile
  echo unset JAVA_PTH  >> /home/oracle/.bash_profile
  chown oracle:dba /home/oracle/.bash_profile

  # passwd oracle

# .bash_profile

cat > /home/oracle/.bashrc << EOF
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
EOF

cat > /home/oracle/.bash_profile << EOF
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
unset JAVA_HOME
unset JAVA_PTH
export HOSTNAME=$HOSTNAME_LWR
export ORACLE_HOSTNAME=$HOSTNAME_LWR
#export ORACLE_SID=$DB_SID
export ORACLE_BASE=/opt/app/oracle/$ORA_DB_VERSION/base
export ORACLE_HOME=/opt/app/oracle/$ORA_DB_VERSION/base/dbhome

export PATH=$PATH:/opt/app/oracle/$ORA_DB_VERSION/base/dbhome/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

#. /usr/local/bin/oraenv


EOF

  mkdir /opt/yourcompany/backup/oracle/$DB_SID
  mkdir /opt/yourcompany/backup/oracle/$DB_SID/archivelog
  mkdir /opt/yourcompany/backup/oracle/$DB_SID/autobackup
  chown -R oracle:dba /opt/yourcompany/backup/oracle

if [ ! -f /etc/security/limits.conf.original ]; then
    cp /etc/security/limits.conf /etc/security/limits.conf.original
  fi

  cat /etc/security/limits.conf.original > /etc/security/limits.conf
  cat >>/etc/security/limits.conf <<EOF
oracle soft memlock unlimited
oracle hard memlock unlimited
oracle soft nofile  65536
oracle hard nofile  65536
oracle soft nproc   16384
oracle hard nproc   16384
EOF

  cat > /etc/profile.d/oracle.sh << EOF
export ORACLE_BASE=/opt/app/oracle/$ORA_DB_VERSION/base
export ORACLE_HOME=/opt/app/oracle/$ORA_DB_VERSION/base/dbhome
#export ORACLE_SID=$DB_SID
export ORAENV_ASK=NO
#. /usr/local/bin/oraenv
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
EOF

# Compute number of 2M hugepages for 45% of available memory
HUGEPAGES=`echo "45*$(cat /proc/meminfo | grep -i MemTotal | awk '{print $2}')/100/1024/2" | bc`

# Oracle recommends shmmax = 1/2 total RAM - to be adjusted to hugepages
SHMMAX=`echo "1024*$(cat /proc/meminfo | grep -i MemTotal | awk '{print $2}')/2" | bc`
# RedHat recommends shmmall = 100% of RAM pages of 4K
SHMALL=`echo "1024*$(cat /proc/meminfo | grep -i MemTotal | awk '{print $2}')/4096" | bc`

if [ ! -f /etc/sysctl.conf.original ]; then
  cp /etc/sysctl.conf /etc/sysctl.conf.original
fi

  cat /etc/sysctl.conf.original >/etc/sysctl.conf
  cat >>/etc/sysctl.conf << EOF

#------------------------------------------------------------
# recommended parameters for Oracle
#------------------------------------------------------------
kernel.sem                      = 250   32000   100      128

kernel.shmmax                   = $SHMMAX
kernel.shmall                   = $SHMALL
kernel.shmmni                   = 4096
net.core.rmem_default           = 262144
net.core.wmem_default           = 262144

#added for Oracle 11g
fs.file-max                     = 6815744
net.ipv4.ip_local_port_range    = 9000 65500
net.core.rmem_max               = 4194304
net.core.wmem_max               = 1048576
fs.aio-max-nr                   = 1048576

# Set up the # of hugepages to 45% of total RAM
vm.nr_hugepages                  = $HUGEPAGES

EOF

  if [ "$RAC" = "Y" ]; then
    echo >> /etc/sysctl.conf
    echo "# Recommended settings for Oracle RAC" >> /etc/sysctl.conf
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.dirty_background_ratio=3" >> /etc/sysctl.conf
    echo "vm.dirty_ratio=40" >> /etc/sysctl.conf
    echo "vm.dirty_expire_centisecs=500" >> /etc/sysctl.conf
    echo "vm.dirty_writeback_centisecs=100" >> /etc/sysctl.conf
    echo >> /etc/sysctl.conf
    echo "# Disable ASLR" >> /etc/sysctl.conf
    echo "kernel.randomize_va_space=0" >> /etc/sysctl.conf
    echo "kernel.exec-shield=0" >> /etc/sysctl.conf

    # NTP service must run with the -x option
    if ! grep "\-x" /etc/sysconfig/ntpd; then
     sed -i "s#\-u#\-x\ \-u#g" /etc/sysconfig/ntpd
    fi

    # Kernel must not use transparent hugepages in memory
    if ! grep "transparent_hugepage=never" /boot/grub/grub.conf; then
     sed -i "s#quiet#quiet\ transparent_hugepage\=never#g" /boot/grub/grub.conf
    fi

    # Disable SELinux
    SELIN=`grep SELINUX /etc/sysconfig/selinux | cut -d '=' -f 2`
    if [ "$SELIN" != "disabled"; then
     sed -i "s#SELINUX\=$SELIN#SELINUX\=disabled#g" /etc/sysconfig/selinux
    fi

    # Network config
    NOZEROCONF=`grep NOZEROCONF /etc/sysconfig/network | cut -d '=' -f 2`
    if [ -z $NOZEROCONF ]; then
      echo "NOZEROCONF=YES" >> /etc/sysconfig/network
    elif [ "$NOZEROCONF" != "YES" ]; then
      sed -i "s#NOZEROCONF\=$NOZEROCONF#NOZEROCONF\=YES#g" /etc/sysconfig/network
    fi
  fi

  # Reload Kernel parameters
  /sbin/sysctl -p

  # Hangcheck timer
  echo "/sbin/modprobe hangcheck-timer hangcheck_tick=30 hangcheck_margin=180" >> /etc/rc.local
  /sbin/modprobe hangcheck-timer hangcheck_tick=30 hangcheck_margin=180
  lsmod | grep hangcheck_timer
}

#
# Packages for Oracle installation
#

#
# OracleASM
#
install_oracle_asm() {
  ORA_DISTRO_URL=${DB_DISTRO_URL}/oracle/Linux/x64/oracleasm
  OS_DISTRO_URL=${OS_PLATFORM_UPR}${OS_RELEASE}_DISTRO_URL
  PKG_LIST=ORA_ASM_PACKAGES_$OS_PLATFORM_UPR$OS_RELEASE

  if [ $OS_RELEASE -eq 6 ];then
     yum install kmod-oracleasm -y
  fi

#echo ${ORA_DISTRO_URL} - ${!PKG_LIST}

  case $OS_PLATFORM_UPR in
    RHEL)
      install_packages_rpm ${ORA_DISTRO_URL} ${!PKG_LIST}
    ;;
    CENTOS)
      echo install_packages_rpm ${ORA_DISTRO_URL} ${!PKG_LIST}
    ;;
    *)
      exit_on_error "unsupported OS platform: $OS_PLATFORM_UPR"
    ;;
  esac

# sed to update udev/90...

  /usr/sbin/oracleasm configure -i -e -u oracle -g dba -o "dm" -x "sd"<< EOF
oracle
dba
y
y
EOF

  service oracleasm restart
}

# Creating OracleASM disk
create_ora_asm_disk() {

  if [ "$ASM" = N ]; then
   /usr/sbin/oracleasm scandisks
   return
  fi

  ASMDATA=`oracleasm listdisks | grep ORA_DATA_01`
  if [ "$ASMDATA" != "ORA_DATA_01" ]; then
    /sbin/lvcreate -n ora_data_01 -L 10G vg02
    /usr/sbin/oracleasm createdisk ora_data_01 /dev/vg02/ora_data_01
  fi

  ASMREDO=`oracleasm listdisks | grep ORA_REDO_01`
  if [ "$ASMREDO" != "ORA_REDO_01" ]; then
    /sbin/lvcreate -n ora_redo_01 -L 1G vg02
    /usr/sbin/oracleasm createdisk ora_redo_01 /dev/vg02/ora_redo_01
  fi

  # Create Cluster Registry diskgroup for RAC
  if [ "$RAC" = "Y" ]; then
    /sbin/lvcreate -n ora_ocr_01 -L 1G vg02
    /usr/sbin/oracleasm createdisk ora_ocr /dev/vg02/ora_ocr_01
  fi

  /usr/sbin/oracleasm init
}

install_oracle_prerequisites() {
  OS_DISTRO_URL=${OS_PLATFORM_UPR}${OS_RELEASE}_DISTRO_URL
  PKG_LIST_NODEPS=ORA_DEP_PACKAGES_NODEPS_$OS_PLATFORM_UPR$OS_RELEASE
  PKG_LIST="ORA_DEP_PACKAGES_$OS_PLATFORM_UPR$OS_RELEASE"

  # Get latest C/C++ compiler
  yum install gcc -y
  yum install gcc-c++ -y
  yum install device-mapper-multipath -y
  mpathconf --enable --with_multipathd y
  chkconfig multipathd on
  yum install iscsi-initiator-utils -y
  chkconfig iscsid on
  yum install unixODBC -y
  yum install nc -y

  # Install DNS service for RAC
  if [ "$RAC" = "Y" ]; then
   yum install bind bind-libs bind-utils -y
   yum remove avahi-daemon -y
   chkconfig named on
  fi

  # Install local RPMs
  case $OS_PLATFORM_UPR in
    RHEL)
      install_packages_rpm_nodeps ${!OS_DISTRO_URL} ${!PKG_LIST_NODEPS}
      install_packages_rpm ${!OS_DISTRO_URL} ${!PKG_LIST}
      #install_packages_rpm_nodeps $RHEL5_DISTRO_URL $ORA_DEP_PACKAGES_NODEPS_RHEL5
      #install_packages_rpm $RHEL5_DISTRO_URL $ORA_DEP_PACKAGES_RHEL5
    ;;
    CENTOS)
      echo install_packages_rpm_nodeps $OS_DISTRO_URL ${!PKG_LIST_NODEPS}
      echo install_packages_rpm $OS_DISTRO_URL ${!PKG_LIST}
    ;;
    *)
      exit_on_error "unsupported OS platform: $OS_PLATFORM_UPR"
    ;;
  esac


}

unpack_oracle_distro(){
# $1 -- repository URL
# $2 -- list of packages to install

 local src_url=$1
 local arg=("$@")

  [ -d /opt/app/oracle/oracle_install ] && rm -rf --preserve-root /opt/app/oracle/oracle_install

  mkdir /opt/app/oracle/oracle_install

 for ((i=1;i<$#;i++)); do {
   # TODO: parallelize this piece of code
   #wget -O /opt/app/oracle/oracle_install/${arg[i]} $src_url/${arg[i]}
   cp $src_url/${arg[i]} /opt/app/oracle/oracle_install/${arg[i]}
   unzip -d /opt/app/oracle/oracle_install /opt/app/oracle/oracle_install/${arg[i]}
   rm -f /opt/app/oracle/oracle_install/${arg[i]}
  }
 done;

 chown -R oracle:dba /opt/app/oracle/oracle_install
}



#
# MAIN
#

if [ $# == 0 ]; then {
  usage_help
  EXIT_CODE=1
} else {
  while [[ $# > 0 ]]
  do
    key="$1"

    case $key in
       "")
          usage_help
          EXIT_CODE=1
          ;;
         --sid|-s)
          DB_SID=$2
          shift
          ;;
       --rac|-R)
          RAC=Y
          ;;
       --noasm|-N)
          ASM=N
          ;;
       --verbose|-v)
          DEBUG=1
          ;;
        *)
          echo "ERROR: unknown option $key!"
          EXIT_CODE=1
          ;;
    esac
    shift
  done
}
fi

if [ $EXIT_CODE == 0 ] ; then

  [ "$DB_SID" == "" ] && exit_on_error "no DB SID name provided!"

  identify_os

  # dump_env
  create_filesystems
  mount_sw_depot
  install_oracle_prerequisites
  create_oracle_environment
  install_oracle_asm
  create_ora_asm_disk
  unpack_oracle_distro $DB_DISTRO_URL/oracle/11.2.0.4 $ORA_DISTRO_PACKAGES
fi

exit $EXIT_CODE


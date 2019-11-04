#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/setup.sh,v 2.0.1.2 2019/04/29 08:37:39 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      setup.sh - 
#
#    DESCRIPTION
#      Creates an Oracle RAC (Real Application Cluster) Vagrant virtual machine.
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------

run_user_scripts() {
  # run user-defined post-setup scripts
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Running user-defined post-setup scripts"
  echo "-----------------------------------------------------------------"
  for f in /vagrant/userscripts/*
    do
      case "${f,,}" in
        *.sh)
          echo -e "${INFO}`date +%F' '%T`: running $f"
          . "$f"
          echo -e "${INFO}`date +%F' '%T`: Done running $f"
          ;;
        *.sql)
          echo -e "${INFO}`date +%F' '%T`: running $f"
          su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
          echo -e "${INFO}`date +%F' '%T`: Done running $f"
          ;;
        /vagrant/userscripts/put_custom_scripts_here.txt)
          :
          ;;
        *)
          echo -e "${INFO}`date +%F' '%T`: ignoring $f"
          ;;
      esac
    done
}

make_09_gi_installation() {
cat > /vagrant_scripts/09_gi_installation.sh <<EOF
. /vagrant_config/setup.env
${GI_HOME}/gridSetup.sh -ignorePrereq -waitforcompletion -silent \\
    -responseFile ${GI_HOME}/install/response/gridsetup.rsp \\
    INVENTORY_LOCATION=${ORA_INVENTORY} \\
    SELECTED_LANGUAGES=${ORA_LANGUAGES} \\
EOF

if [ "${ORESTART}" == "true" ]
then
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.option=HA_CONFIG \\
EOF
else
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.option=CRS_CONFIG \\
EOF
fi

cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    ORACLE_BASE=${GRID_BASE} \\
    oracle.install.asm.OSDBA=asmdba \\
    oracle.install.asm.OSOPER=asmoper \\
    oracle.install.asm.OSASM=asmadmin \\
EOF
if [ "${ORESTART}" == "false" ]
then
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.crs.config.scanType=LOCAL_SCAN \\
    oracle.install.crs.config.gpnp.scanName=${SCAN_NAME} \\
    oracle.install.crs.config.gpnp.scanPort=${SCAN_PORT} \\
EOF
fi

cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \\
    oracle.install.crs.config.configureAsExtendedCluster=false \\
    oracle.install.crs.config.clusterName=${CLUSTER_NAME} \\
EOF

if [ "${NOMGMTDB}" == "true" ]
then
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle_install_crs_ConfigureMgmtDB=false \\
EOF
else
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle_install_crs_ConfigureMgmtDB=true \\
EOF
fi

if [ "${ORESTART}" == "false" ]
then
  cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.crs.config.clusterNodes=${NODE1_FQ_HOSTNAME}:${NODE1_FQ_VIPNAME}:HUB,${NODE2_FQ_HOSTNAME}:${NODE2_FQ_VIPNAME}:HUB \\
    oracle.install.crs.config.networkInterfaceList=${NET_DEVICE1}:${PUBLIC_SUBNET}:1,${NET_DEVICE2}:${PRIVATE_SUBNET}:5 \\
EOF
fi

cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.crs.config.gpnp.configureGNS=false \\
    oracle.install.crs.config.autoConfigureClusterNodeVIP=false \\
    oracle.install.asm.configureGIMRDataDG=false \\
    oracle.install.crs.config.useIPMI=false \\
    oracle.install.asm.storageOption=ASM \\
    oracle.install.asmOnNAS.configureGIMRDataDG=false \\
    oracle.install.asm.SYSASMPassword=${SYS_PASSWORD} \\
    oracle.install.asm.diskGroup.name=DATA \\
    oracle.install.asm.diskGroup.redundancy=EXTERNAL \\
    oracle.install.asm.diskGroup.AUSize=4 \\
EOF

if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
then
DISKS=`ls -dm /dev/ORCL_DISK*_p1`
DISKSFG=`echo $DISKS| tr ', ' ',,'`
DISKSFG=${DISKSFG}","
DISKS=`echo $DISKS|tr -d ' '`
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/ORCL_* \\
    oracle.install.asm.configureAFD=true \\
EOF
else
DISKS=`ls -dm /dev/oracleasm/disks/ORCL_DISK*_P1`
DISKSFG=`echo $DISKS| tr ', ' ',,'`
DISKSFG=${DISKSFG}","
DISKS=`echo $DISKS|tr -d ' '`
cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/ORCL_* \\
EOF
fi

cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.asm.gimrDG.AUSize=1 \\
    oracle.install.asm.monitorPassword=${SYS_PASSWORD} \\
    oracle.install.crs.configureRHPS=false \\
    oracle.install.crs.config.ignoreDownNodes=false \\
    oracle.install.config.managementOption=NONE \\
    oracle.install.config.omsPort=0 \\
    oracle.install.crs.rootconfig.executeRootScript=false
EOF
}

make_11_gi_config() {
cat > /vagrant_scripts/11_gi_config.sh <<EOF
. /vagrant_config/setup.env
${GI_HOME}/gridSetup.sh -silent -executeConfigTools \\
    -responseFile ${GI_HOME}/install/response/gridsetup.rsp \\
    INVENTORY_LOCATION=${ORA_INVENTORY} \\
    SELECTED_LANGUAGES=${ORA_LANGUAGES} \\
EOF

if [ "${ORESTART}" == "true" ]
then
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.option=HA_CONFIG \\
EOF
else
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.option=CRS_CONFIG \\
EOF
fi

cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    ORACLE_BASE=${GRID_BASE} \\
    oracle.install.asm.OSDBA=asmdba \\
    oracle.install.asm.OSOPER=asmoper \\
    oracle.install.asm.OSASM=asmadmin \\
EOF

if [ "${ORESTART}" == "false" ]
then
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.crs.config.scanType=LOCAL_SCAN \\
    oracle.install.crs.config.gpnp.scanName=${SCAN_NAME} \\
    oracle.install.crs.config.gpnp.scanPort=${SCAN_PORT} \\
    oracle.install.crs.config.clusterName=${CLUSTER_NAME} \\
EOF
fi

cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \\
    oracle.install.crs.config.configureAsExtendedCluster=false \\
EOF

if [ "${NOMGMTDB}" == "true" ]
then
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle_install_crs_ConfigureMgmtDB=false \\
EOF
else
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle_install_crs_ConfigureMgmtDB=true \\
EOF
fi

if [ "${ORESTART}" == "false" ]
then
  cat >> /vagrant_scripts/09_gi_installation.sh <<EOF
    oracle.install.crs.config.clusterNodes=${NODE1_FQ_HOSTNAME}:${NODE1_FQ_VIPNAME}:HUB,${NODE2_FQ_HOSTNAME}:${NODE2_FQ_VIPNAME}:HUB \\
    oracle.install.crs.config.networkInterfaceList=${NET_DEVICE1}:${PUBLIC_SUBNET}:1,${NET_DEVICE2}:${PRIVATE_SUBNET}:5 \\
EOF
fi

cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.crs.config.gpnp.configureGNS=false \\
    oracle.install.crs.config.autoConfigureClusterNodeVIP=false \\
    oracle.install.asm.configureGIMRDataDG=false \\
    oracle.install.crs.config.useIPMI=false \\
    oracle.install.asm.storageOption=ASM \\
    oracle.install.asmOnNAS.configureGIMRDataDG=false \\
    oracle.install.asm.SYSASMPassword=${SYS_PASSWORD} \\
    oracle.install.asm.diskGroup.name=DATA \\
    oracle.install.asm.diskGroup.redundancy=EXTERNAL \\
    oracle.install.asm.diskGroup.AUSize=4 \\
EOF

if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
then
DISKS=`ls -dm /dev/ORCL_DISK*_p1`
DISKSFG=`echo $DISKS| tr ', ' ',,'`
DISKSFG=${DISKSFG}","
DISKS=`echo $DISKS|tr -d ' '`
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/ORCL_* \\
    oracle.install.asm.configureAFD=true \\
EOF
else
DISKS=`ls -dm /dev/oracleasm/disks/ORCL_DISK*_P1`
DISKSFG=`echo $DISKS| tr ', ' ',,'`
DISKSFG=${DISKSFG}","
DISKS=`echo $DISKS|tr -d ' '`
cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/ORCL_* \\
EOF
fi

cat >> /vagrant_scripts/11_gi_config.sh <<EOF
    oracle.install.asm.gimrDG.AUSize=1 \\
    oracle.install.asm.monitorPassword=${SYS_PASSWORD} \\
    oracle.install.crs.configureRHPS=false \\
    oracle.install.crs.config.ignoreDownNodes=false \\
    oracle.install.config.managementOption=NONE \\
    oracle.install.config.omsPort=0 \\
    oracle.install.crs.rootconfig.executeRootScript=false
EOF
}

make_13_RDBMS_software_installation() {
cat > /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
. /vagrant_config/setup.env
EOF

DB_MAJOR=$(echo "${DB_SOFTWARE_VER}" | cut -c1-2)
if [ "${DB_MAJOR}" == "12" ]
then
  cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
${DB_HOME}/database/runInstaller -ignorePrereq -waitforcompletion -silent \\
        -responseFile ${DB_HOME}/database/response/db_install.rsp \\
EOF
else
  cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
${DB_HOME}/runInstaller -ignorePrereq -waitforcompletion -silent \\
        -responseFile ${DB_HOME}/install/response/db_install.rsp \\
EOF
fi

cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
        oracle.install.option=INSTALL_DB_SWONLY \\
        ORACLE_HOSTNAME=${ORACLE_HOSTNAME} \\
        UNIX_GROUP_NAME=oinstall \\
        INVENTORY_LOCATION=${ORA_INVENTORY} \\
        SELECTED_LANGUAGES=${ORA_LANGUAGES} \\
        ORACLE_HOME=${DB_HOME} \\
        ORACLE_BASE=${DB_BASE} \\
        oracle.install.db.InstallEdition=EE \\
        oracle.install.db.OSDBA_GROUP=dba \\
        oracle.install.db.OSBACKUPDBA_GROUP=dba \\
        oracle.install.db.OSDGDBA_GROUP=dba \\
        oracle.install.db.OSKMDBA_GROUP=dba \\
        oracle.install.db.OSRACDBA_GROUP=dba \\
EOF

if [ "${ORESTART}" == "false" ]
then
  cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
        oracle.install.db.CLUSTER_NODES=${NODE1_HOSTNAME},${NODE2_HOSTNAME} \\
EOF
fi

if [ "${DB_TYPE}" == "RACONE" ]
then
  cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
        oracle.install.db.isRACOneInstall=true \\
EOF
else
  cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
        oracle.install.db.isRACOneInstall=false \\
EOF
fi

cat >> /vagrant_scripts/13_RDBMS_software_installation.sh <<EOF
        oracle.install.db.rac.serverpoolCardinality=0 \\
        oracle.install.db.config.starterdb.type=GENERAL_PURPOSE \\
        oracle.install.db.ConfigureAsContainerDB=true \\
        SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \\
        DECLINE_SECURITY_UPDATES=true
EOF
}

make_14_create_database() {
cat > /vagrant_scripts/14_create_database.sh <<EOF
. /vagrant_config/setup.env
${DB_HOME}/bin/dbca -silent -createDatabase \\
  -templateName General_Purpose.dbc \\
  -initParams db_recovery_file_dest_size=2G \\
  -responseFile NO_VALUE \\
  -gdbname ${DB_NAME} \\
  -characterSet AL32UTF8 \\
  -sysPassword ${SYS_PASSWORD} \\
  -systemPassword ${SYS_PASSWORD} \\
EOF

if [ "${CDB}" == "true" ]
then
cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -createAsContainerDatabase true \\
  -numberOfPDBs 1 \\
  -pdbName ${PDB_NAME} \\
  -pdbAdminPassword ${PDB_PASSWORD} \\
EOF
fi

cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -databaseType MULTIPURPOSE \\
  -automaticMemoryManagement false \\
  -totalMemory 2048 \\
  -redoLogFileSize 50 \\
  -emConfiguration NONE \\
  -ignorePreReqs \\
EOF

if [ "${DB_TYPE}" == "RAC" ]
then
    cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -databaseConfigType RAC \\
EOF
elif [ "${DB_TYPE}" == "RACONE" ]
then
    cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -databaseConfigType RACONE \\
  -RACOneNodeServiceName ${DB_NAME}_srv \\
EOF
elif [ "${DB_TYPE}" == "SINGLE" ]
then
    cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -databaseConfigType SINGLE \\
EOF
fi

if [ "${DB_TYPE}" == "RAC" ] || [ "${DB_TYPE}" == "RACONE" ]
then
  if [ "${ORESTART}" == "false" ]
  then
    cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -nodelist ${NODE1_HOSTNAME},${NODE2_HOSTNAME} \\
EOF
  else
    if [ `hostname` == ${NODE1_HOSTNAME} ]
    then
      cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -nodelist ${NODE1_HOSTNAME} \\
EOF
    elif [ `hostname` == ${NODE2_HOSTNAME} ]
    then
      cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -nodelist ${NODE2_HOSTNAME} \\
EOF
    fi
  fi
fi

cat >> /vagrant_scripts/14_create_database.sh <<EOF
  -storageType ASM \\
  -diskGroupName +DATA \\
  -recoveryGroupName +RECO \\
  -asmsnmpPassword ${SYS_PASSWORD}
EOF
}

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
if [[ `hostname` == ${VM2_NAME} || (`hostname` == ${VM1_NAME} && "${ORESTART}" == "true") ]]
then
  # build the setup.env
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make the setup.env"
  echo "-----------------------------------------------------------------"

  GI_MAJOR=$(echo "${GI_SOFTWARE_VER}" | cut -c1-2)
  GI_MAINTENANCE=$(echo "${GI_SOFTWARE_VER}" | cut -c3)
  GI_APP=$(echo "${GI_SOFTWARE_VER}" | cut -c4)
  GI_COMP=$(echo "${GI_SOFTWARE_VER}" | cut -c5)
  GI_VERSION=${GI_MAJOR}"."${GI_MAINTENANCE}"."${GI_APP}"."${GI_COMP}
  GI_HOME="/u01/app/"$GI_VERSION"/grid"

  DB_MAJOR=$(echo "${DB_SOFTWARE_VER}" | cut -c1-2)
  DB_MAINTENANCE=$(echo "${DB_SOFTWARE_VER}" | cut -c3)
  DB_APP=$(echo "${DB_SOFTWARE_VER}" | cut -c4)
  DB_COMP=$(echo "${DB_SOFTWARE_VER}" | cut -c5)
  DB_VERSION=${DB_MAJOR}"."${DB_MAINTENANCE}"."${DB_APP}"."${DB_COMP}
  DB_HOME="/u01/app/oracle/product/"$DB_VERSION"/dbhome_1"

  node1_public_ipoct1=$(echo ${NODE1_PUBLIC_IP} | tr "." " " | awk '{ print $1 }')
  node1_public_ipoct2=$(echo ${NODE1_PUBLIC_IP} | tr "." " " | awk '{ print $2 }')
  node1_public_ipoct3=$(echo ${NODE1_PUBLIC_IP} | tr "." " " | awk '{ print $3 }')
  node1_public_ipoct4=$(echo ${NODE1_PUBLIC_IP} | tr "." " " | awk '{ print $4 }')
  #
  node1_private_ipoct1=$(echo ${NODE1_PRIV_IP} | tr "." " " | awk '{ print $1 }')
  node1_private_ipoct2=$(echo ${NODE1_PRIV_IP} | tr "." " " | awk '{ print $2 }')
  node1_private_ipoct3=$(echo ${NODE1_PRIV_IP} | tr "." " " | awk '{ print $3 }')
  node1_private_ipoct4=$(echo ${NODE1_PRIV_IP} | tr "." " " | awk '{ print $4 }')

  PUBLIC_SUBNET="$node1_public_ipoct1.$node1_public_ipoct2.$node1_public_ipoct3.0"
  PRIVATE_SUBNET="$node1_private_ipoct1.$node1_private_ipoct2.$node1_private_ipoct3.0"

  NET_DEVICE1=`ip a | grep "3: " | awk '{print $2}'`
  NET_DEVICE1=${NET_DEVICE1:0:-1}
  NET_DEVICE2=`ip a | grep "4: " | awk '{print $2}'`
  NET_DEVICE2=${NET_DEVICE2:0:-1}

cat <<EOL > /vagrant_config/setup.env
#----------------------------------------------------------
# Env Variables
#----------------------------------------------------------
export PREFIX_NAME=$PREFIX_NAME
#----------------------------------------------------------
#----------------------------------------------------------
export GI_SOFTWARE=$GI_SOFTWARE
export DB_SOFTWARE=$DB_SOFTWARE
#----------------------------------------------------------
#----------------------------------------------------------
export GI_VERSION=$GI_VERSION
export DB_VERSION=$DB_VERSION
#----------------------------------------------------------
#----------------------------------------------------------
export SYS_PASSWORD=$SYS_PASSWORD
export PDB_PASSWORD=$PDB_PASSWORD
#----------------------------------------------------------
#----------------------------------------------------------
export P1_RATIO=$P1_RATIO
export ASM_LIB_TYPE=$ASM_LIB_TYPE
export NOMGMTDB=$NOMGMTDB
export ORESTART=$ORESTART
#----------------------------------------------------------
#----------------------------------------------------------
export PUBLIC_SUBNET=$PUBLIC_SUBNET
export PRIVATE_SUBNET=$PRIVATE_SUBNET
#
export DNS_PUBLIC_IP=$DNS_PUBLIC_IP
export NODE1_PUBLIC_IP=$NODE1_PUBLIC_IP
export NODE2_PUBLIC_IP=$NODE2_PUBLIC_IP
#
export NODE1_PRIV_IP=$NODE1_PRIV_IP
export NODE2_PRIV_IP=$NODE2_PRIV_IP
#
export NODE1_VIP_IP=$NODE1_VIP_IP
export NODE2_VIP_IP=$NODE2_VIP_IP
#
export SCAN_IP1=$SCAN_IP1
export SCAN_IP2=$SCAN_IP2
export SCAN_IP3=$SCAN_IP3
#----------------------------------------------------------
#----------------------------------------------------------
export DOMAIN_NAME=localdomain

export NODE1_HOSTNAME=${VM1_NAME}
export NODE2_HOSTNAME=${VM2_NAME}
export NODE1_FQ_HOSTNAME=\${NODE1_HOSTNAME}.\${DOMAIN_NAME}
export NODE2_FQ_HOSTNAME=\${NODE2_HOSTNAME}.\${DOMAIN_NAME}

export NODE1_VIPNAME=\${NODE1_HOSTNAME}-vip
export NODE2_VIPNAME=\${NODE2_HOSTNAME}-vip
export NODE1_FQ_VIPNAME=\${NODE1_VIPNAME}.\${DOMAIN_NAME}
export NODE2_FQ_VIPNAME=\${NODE2_VIPNAME}.\${DOMAIN_NAME}

export NODE1_PRIVNAME=\${NODE1_HOSTNAME}-priv
export NODE2_PRIVNAME=\${NODE2_HOSTNAME}-priv
export NODE1_FQ_PRIVNAME=\${NODE1_PRIVNAME}.\${DOMAIN_NAME}
export NODE2_FQ_PRIVNAME=\${NODE2_PRIVNAME}.\${DOMAIN_NAME}
#----------------------------------------------------------
#----------------------------------------------------------
export CLUSTER_NAME=${PREFIX_NAME}-cluster

export ORA_LANGUAGES=$ORA_LANGUAGES

export SCAN_NAME=${PREFIX_NAME}-scan
export FQ_SCAN_NAME=\${SCAN_NAME}.\${DOMAIN_NAME}
export SCAN_PORT=1521

export ORA_INVENTORY=/u01/app/oraInventory
export GRID_BASE=/u01/app/grid
export DB_BASE=/u01/app/oracle

export GI_HOME=${GI_HOME}
export DB_HOME=${DB_HOME}

export DB_NAME=$DB_NAME
export PDB_NAME=$PDB_NAME
export DB_TYPE=$DB_TYPE
#----------------------------------------------------------
#----------------------------------------------------------
export NET_DEVICE1=${NET_DEVICE1}
export NET_DEVICE2=${NET_DEVICE2}
#----------------------------------------------------------
#----------------------------------------------------------
export INFO='\033[0;34mINFO: \033[0m'
export ERROR='\033[1;31mERROR: \033[0m'
export SUCCESS='\033[1;32mSUCCESS: \033[0m'
#----------------------------------------------------------
#----------------------------------------------------------
EOL
fi


# Setup the env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup the environment variables"
echo "-----------------------------------------------------------------"
. /vagrant_config/setup.env


# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Checking parameters"
echo "-----------------------------------------------------------------"
if [ "$P1_RATIO" -eq "$P1_RATIO" ] 2>/dev/null
then
  echo "Partition ratio is set to $P1_RATIO" >/dev/null
else
  echo -e "${ERROR}`date +%F' '%T`: Partition ratio option must be an integer, exiting...";
  exit 1
fi

if [ $P1_RATIO -lt 10 ] && [ $P1_RATIO -gt 80 ] 
then
  echo -e "${ERROR}`date +%F' '%T`: Partition ratio should be a value between 10 and 80, exiting...";
  exit 1
fi 

if [ "${ASM_LIB_TYPE}" != "ASMLIB" ] && [ "${ASM_LIB_TYPE}" != "ASMFD" ]
then
  echo -e "${ERROR}`date +%F' '%T`: Parameter 'asm_lib_type' must be 'ASMLIB' or 'ASMFD', exiting...";
  exit 1
fi

if [ "${ORESTART}" != "true" ] && [ "${ORESTART}" != "false" ]
then
  echo -e "${ERROR}`date +%F' '%T`: Parameter 'orestart' must be 'true' or 'false', exiting...";
  exit 1
fi

if [ "${NOMGMTDB}" != "true" ] && [ "${NOMGMTDB}" != "false" ]
then
  echo -e "${ERROR}`date +%F' '%T`: Parameter 'nomgmtdb' must be 'true' or 'false', exiting...";
  exit 1
fi

if [ "${DB_TYPE}" != "SI" ] && [ "${DB_TYPE}" != "RACONE" ] && [ "${DB_TYPE}" != "RAC" ]
then
  echo -e "${ERROR}`date +%F' '%T`: Parameter 'db_type' must be 'SI' or 'RACONE' or 'RAC', exiting...";
  exit 1
fi

if [[ "${ORESTART}" == "true" && ("${DB_TYPE}" == "RACONE" || "${DB_TYPE}" == "RAC" ) ]]
then
  echo -e "${ERROR}`date +%F' '%T`: Oracle Restart supports 'SI' only, exiting...";
  exit 1
fi

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Fix locale warnings"
echo "-----------------------------------------------------------------"
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

# set system time zone
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set system time zone"
echo "-----------------------------------------------------------------"
sudo timedatectl set-timezone $SYSTEM_TIMEZONE

#--------------------------------------------------------------------
#--------------------------------------------------------------------
# Setting-up purgelog
sh /vagrant_scripts/00_purgelog.sh

# Setting-up /u01 disk
sh /vagrant_scripts/01_setup_u01.sh $BOX_DISK_NUM

# Install OS Pachages
sh /vagrant_scripts/02_install_os_packages.sh

# Setup /etc/hosts & /etc/resolv.conf
sh /vagrant_scripts/03_setup_hosts.sh

# Setup chrony
sh /vagrant_scripts/04_setup_chrony.sh

# Setup shared disks
BOX_DISK_NUM=$((BOX_DISK_NUM + 1))
sh /vagrant_scripts/05_setup_shared_disks.sh $BOX_DISK_NUM

# Setup users
sh /vagrant_scripts/06_setup_users.sh

# Setup users password
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set root, oracle and grid password"
echo "-----------------------------------------------------------------"
echo ${ROOT_PASSWORD}   | passwd --stdin root
echo ${GRID_PASSWORD}   | passwd --stdin grid
echo ${ORACLE_PASSWORD} | passwd --stdin oracle


# Actions on node1 only
if [ `hostname` == ${VM1_NAME} ] && [ "${ORESTART}" == "false" ]
then
  # unzip grid software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Unzip grid software"
  echo "-----------------------------------------------------------------"
  cd ${GI_HOME}
  unzip -oq /vagrant/ORCL_software/${GI_SOFTWARE}
  chown -R grid:oinstall ${GI_HOME}

  # setup ssh equivalence (node1 only)
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Setup user equivalence"
  echo "-----------------------------------------------------------------"
  expect /vagrant_scripts/07_setup_user_equ.expect grid   ${GRID_PASSWORD}   ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh
  expect /vagrant_scripts/07_setup_user_equ.expect oracle ${ORACLE_PASSWORD} ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh

  # Install cvuqdisk package
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Install cvuqdisk package"
  echo "-----------------------------------------------------------------"
  yum install -y ${GI_HOME}/cv/rpm/cvuqdisk*.rpm
elif [ "${ORESTART}" == "true" ]
then
  # unzip grid software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Unzip grid software"
  echo "-----------------------------------------------------------------"
  cd ${GI_HOME}
  unzip -oq /vagrant/ORCL_software/${GI_SOFTWARE}
  chown -R grid:oinstall ${GI_HOME}
  
  # Install cvuqdisk package
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Install cvuqdisk package"
  echo "-----------------------------------------------------------------"
  yum install -y ${GI_HOME}/cv/rpm/cvuqdisk*.rpm
fi

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
then
  # Setting-up asmfd disks label
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: ASMFD disks label setup"
  echo "-----------------------------------------------------------------"
  sh /vagrant_scripts/08_asmfd_label_disk.sh $BOX_DISK_NUM
else
  # Setting-up asmfd disks label
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: ASMLib disks label setup"
  echo "-----------------------------------------------------------------"
  sh /vagrant_scripts/08_asmlib_label_disk.sh $BOX_DISK_NUM
fi
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------

if [ `hostname` == ${VM1_NAME} ] && [ "${ORESTART}" == "false" ]
then
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make GI install command"
  echo "-----------------------------------------------------------------"
  make_09_gi_installation ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure installation as 'RAC'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo -e "${INFO}`date +%F' '%T`: - without MGMTDB: ${NOMGMTDB}"
  echo "-----------------------------------------------------------------"

  su - grid -c 'sh /vagrant_scripts/09_gi_installation.sh'

  #-------------------------------------------------------
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Set root user equivalence"
  echo "-----------------------------------------------------------------"
  expect /vagrant_scripts/07_setup_user_equ.expect root ${ROOT_PASSWORD} ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure setup"
  echo "-----------------------------------------------------------------"
  sh /vagrant_scripts/10_gi_setup.sh
  #-------------------------------------------------------

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make GI config command"
  echo "-----------------------------------------------------------------"
  make_11_gi_config ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure configuration as 'RAC'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo -e "${INFO}`date +%F' '%T`: - without MGMTDB: ${NOMGMTDB}"
  echo "-----------------------------------------------------------------"
  su - grid -c 'sh /vagrant_scripts/11_gi_config.sh'
  #-------------------------------------------------------

  if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
  then
    # Make RECO DG using ASMFD
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: Make RECO DG using ASMFD"
    echo "-----------------------------------------------------------------"
    su - grid -c 'sh /vagrant_scripts/12_Make_ASMFD_RECODG.sh'
  else
    # Make RECO DG using ASMLib
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: Make RECO DG using ASMLib"
    echo "-----------------------------------------------------------------"
    su - grid -c 'sh /vagrant_scripts/12_Make_ASMLib_RECODG.sh'
  fi

  # unzip rdbms software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Unzip RDBMS software"
  echo "-----------------------------------------------------------------"
  cd ${DB_HOME}
  unzip -oq /vagrant/ORCL_software/${DB_SOFTWARE}
  chown -R oracle:oinstall ${DB_HOME}

  # Make 13_RDBMS_software_installation.sh
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make RDBMS software install command"
  echo "-----------------------------------------------------------------"
  make_13_RDBMS_software_installation;

  # install rdbms software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: RDBMS software installation"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/13_RDBMS_software_installation.sh'
  sh ${DB_HOME}/root.sh
  ssh root@${NODE2_HOSTNAME} sh ${DB_HOME}/root.sh

  if [ "${DB_MAJOR}" == "12" ]
  then
    rm -fr ${DB_HOME}/database
  fi

  # Make 14_create_database.sh
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make create database command"
  echo "-----------------------------------------------------------------"
  make_14_create_database;

  # create database 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Create database"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/14_create_database.sh'

  # Check database 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Check database"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/15_Check_database.sh'

elif [ "${ORESTART}" == "true" ]
then
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Making GI install command"
  echo "-----------------------------------------------------------------"
  make_09_gi_installation ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure installation as 'ORestart'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo -e "${INFO}`date +%F' '%T`: - without MGMTDB: ${NOMGMTDB}"
  echo "-----------------------------------------------------------------"
  su - grid -c 'sh /vagrant_scripts/09_gi_installation.sh'

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure setup"
  echo "-----------------------------------------------------------------"
  sh /vagrant_scripts/10_gi_setup.sh

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make GI config command"
  echo "-----------------------------------------------------------------"
  make_11_gi_config ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure configuration as 'ORestart'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo -e "${INFO}`date +%F' '%T`: - without MGMTDB: ${NOMGMTDB}"
  echo "-----------------------------------------------------------------"
  touch /etc/oratab
  chown grid:oinstall /etc/oratab
  su - grid -c 'sh /vagrant_scripts/11_gi_config.sh'

  #-------------------------------------------------------
  if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
  then
    # Make RECO DG using ASMFD
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: Make RECO DG using ASMFD"
    echo "-----------------------------------------------------------------"
    su - grid -c 'sh /vagrant_scripts/12_Make_ASMFD_RECODG.sh'
  else
    # Make RECO DG using ASMLib
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: Make RECO DG using ASMLib"
    echo "-----------------------------------------------------------------"
    su - grid -c 'sh /vagrant_scripts/12_Make_ASMLib_RECODG.sh'
  fi

  # unzip rdbms software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Unzip RDBMS software"
  echo "-----------------------------------------------------------------"
  cd ${DB_HOME}
  unzip -oq /vagrant/ORCL_software/${DB_SOFTWARE}
  chown -R oracle:oinstall ${DB_HOME}

  # Make 13_RDBMS_software_installation.sh
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make RDBMS software installation command"
  echo "-----------------------------------------------------------------"
  make_13_RDBMS_software_installation;

  # install rdbms software 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: RDBMS software installation"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/13_RDBMS_software_installation.sh'
  sh ${DB_HOME}/root.sh

  if [ "${DB_MAJOR}" == "12" ]
  then
    rm -fr ${DB_HOME}/database
  fi

  # Make 14_create_database.sh
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make create database command"
  echo "-----------------------------------------------------------------"
  make_14_create_database;

  # create database 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Create database"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/14_create_database.sh'

  # Check database 
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Check database"
  echo "-----------------------------------------------------------------"
  su - oracle -c 'sh /vagrant_scripts/15_Check_database.sh'
fi

# run user-defined post-setup scripts
run_user_scripts;

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


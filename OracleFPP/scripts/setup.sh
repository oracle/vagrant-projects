#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      setup.sh - 
#
#    DESCRIPTION
#      Creates an Oracle Fleet Patching and Provisioning (FPP) Vagrant virtual machine.
#
#    NOTES
#      DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#      ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     10/01/19 - Creation
#
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│

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
cat > /vagrant/scripts/09_gi_installation.sh <<EOF
. /vagrant/config/setup.env
${GI_HOME}/gridSetup.sh -ignorePrereq -waitforcompletion -silent \\
    -responseFile ${GI_HOME}/install/response/gridsetup.rsp \\
    INVENTORY_LOCATION=${ORA_INVENTORY} \\
    SELECTED_LANGUAGES=${ORA_LANGUAGES} \\
    oracle.install.option=CRS_CONFIG \\
    ORACLE_BASE=${GRID_BASE} \\
    oracle.install.asm.OSDBA=asmdba \\
    oracle.install.asm.OSOPER=asmoper \\
    oracle.install.asm.OSASM=asmadmin \\
    oracle.install.crs.config.scanType=LOCAL_SCAN \\
    oracle.install.crs.config.gpnp.scanName=${SCAN_NAME} \\
    oracle.install.crs.config.gpnp.scanPort=${SCAN_PORT} \\
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \\
    oracle.install.crs.config.configureAsExtendedCluster=false \\
    oracle.install.crs.config.clusterName=${CLUSTER_NAME} \\
    oracle_install_crs_ConfigureMgmtDB=true \\
    oracle.install.crs.config.clusterNodes=${NODE1_FQ_HOSTNAME}:${NODE1_FQ_VIPNAME}:HUB \\
    oracle.install.crs.config.networkInterfaceList=${NET_DEVICE1}:${PUBLIC_SUBNET}:1,${NET_DEVICE2}:${PRIVATE_SUBNET}:5 \\
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
cat >> /vagrant/scripts/09_gi_installation.sh <<EOF
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
cat >> /vagrant/scripts/09_gi_installation.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/ORCL_* \\
EOF
fi

cat >> /vagrant/scripts/09_gi_installation.sh <<EOF
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
cat > /vagrant/scripts/11_gi_config.sh <<EOF
. /vagrant/config/setup.env
${GI_HOME}/gridSetup.sh -silent -executeConfigTools \\
    -responseFile ${GI_HOME}/install/response/gridsetup.rsp \\
    INVENTORY_LOCATION=${ORA_INVENTORY} \\
    SELECTED_LANGUAGES=${ORA_LANGUAGES} \\
    oracle.install.option=CRS_CONFIG \\
    ORACLE_BASE=${GRID_BASE} \\
    oracle.install.asm.OSDBA=asmdba \\
    oracle.install.asm.OSOPER=asmoper \\
    oracle.install.asm.OSASM=asmadmin \\
    oracle.install.crs.config.scanType=LOCAL_SCAN \\
    oracle.install.crs.config.gpnp.scanName=${SCAN_NAME} \\
    oracle.install.crs.config.gpnp.scanPort=${SCAN_PORT} \\
    oracle.install.crs.config.clusterName=${CLUSTER_NAME} \\
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \\
    oracle.install.crs.config.configureAsExtendedCluster=false \\
    oracle_install_crs_ConfigureMgmtDB=true \\
    oracle.install.crs.config.clusterNodes=${NODE1_FQ_HOSTNAME}:${NODE1_FQ_VIPNAME}:HUB \\
    oracle.install.crs.config.networkInterfaceList=${NET_DEVICE1}:${PUBLIC_SUBNET}:1,${NET_DEVICE2}:${PRIVATE_SUBNET}:5 \\
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
cat >> /vagrant/scripts/11_gi_config.sh <<EOF
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
cat >> /vagrant/scripts/11_gi_config.sh <<EOF
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=${DISKSFG} \\
    oracle.install.asm.diskGroup.disks=${DISKS} \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/ORCL_* \\
EOF
fi

cat >> /vagrant/scripts/11_gi_config.sh <<EOF
    oracle.install.asm.gimrDG.AUSize=1 \\
    oracle.install.asm.monitorPassword=${SYS_PASSWORD} \\
    oracle.install.crs.configureRHPS=false \\
    oracle.install.crs.config.ignoreDownNodes=false \\
    oracle.install.config.managementOption=NONE \\
    oracle.install.config.omsPort=0 \\
    oracle.install.crs.rootconfig.executeRootScript=false
EOF
}

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------

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

if [ `hostname` == "${VM1_NAME}" ]
then
  NET_DEVICE2=`ip a | grep "4: " | awk '{print $2}'`
  NET_DEVICE2=${NET_DEVICE2:0:-1}
fi

cat <<EOL > /vagrant/config/setup.env
#----------------------------------------------------------
# Env Variables
#----------------------------------------------------------
export PREFIX_NAME=$PREFIX_NAME
#----------------------------------------------------------
#----------------------------------------------------------
export GI_SOFTWARE=$GI_SOFTWARE
#----------------------------------------------------------
#----------------------------------------------------------
export GI_VERSION=$GI_VERSION
#----------------------------------------------------------
#----------------------------------------------------------
export ASM_LIB_TYPE=$ASM_LIB_TYPE
#----------------------------------------------------------
#----------------------------------------------------------
export PUBLIC_SUBNET=$PUBLIC_SUBNET
export PRIVATE_SUBNET=$PRIVATE_SUBNET
#
export DNS_PUBLIC_IP=$DNS_PUBLIC_IP
export NODE1_PUBLIC_IP=$NODE1_PUBLIC_IP
export NODE1_PRIV_IP=$NODE1_PRIV_IP
export NODE1_VIP_IP=$NODE1_VIP_IP
#
export SCAN_IP1=$SCAN_IP1
export SCAN_IP2=$SCAN_IP2
export SCAN_IP3=$SCAN_IP3
#
export GNS_IP=$GNS_IP
export HA_VIP=$HA_VIP
#
export NODE2_PUBLIC_IP=$NODE2_PUBLIC_IP
#----------------------------------------------------------
#----------------------------------------------------------
export DOMAIN_NAME=$DOMAIN

export NODE1_HOSTNAME=${VM1_NAME}
export NODE1_FQ_HOSTNAME=\${NODE1_HOSTNAME}.\${DOMAIN_NAME}

export NODE1_VIPNAME=\${NODE1_HOSTNAME}-vip
export NODE1_FQ_VIPNAME=\${NODE1_VIPNAME}.\${DOMAIN_NAME}

export NODE1_PRIVNAME=\${NODE1_HOSTNAME}-priv
export NODE1_FQ_PRIVNAME=\${NODE1_PRIVNAME}.\${DOMAIN_NAME}

export NODE2_HOSTNAME=${VM2_NAME}
export NODE2_FQ_HOSTNAME=\${NODE2_HOSTNAME}.\${DOMAIN_NAME}
#----------------------------------------------------------
#----------------------------------------------------------
export CLUSTER_NAME=${PREFIX_NAME}-c

export ORA_LANGUAGES=$ORA_LANGUAGES

export SCAN_NAME=${PREFIX_NAME}-scan
export FQ_SCAN_NAME=\${SCAN_NAME}.\${DOMAIN_NAME}
export SCAN_PORT=1521

export ORA_INVENTORY=/u01/app/oraInventory
export GRID_BASE=/u01/app/grid
export DB_BASE=/u01/app/oracle

export GI_HOME=${GI_HOME}
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

# Setup the env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup the environment variables"
echo "-----------------------------------------------------------------"
. /vagrant/config/setup.env


# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Checking parameters"
echo "-----------------------------------------------------------------"
if [ "${ASM_LIB_TYPE}" != "ASMLIB" ] && [ "${ASM_LIB_TYPE}" != "ASMFD" ]
then
  echo -e "${ERROR}`date +%F' '%T`: Parameter 'asm_lib_type' must be 'ASMLIB' or 'ASMFD', exiting...";
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
if [ `hostname` == "${VM1_NAME}" ]
then
  # Setting-up /u01 disk
  sh /vagrant/scripts/01_setup_u01.sh $BOX_DISK_NUM virtualbox

  # Install OS Pachages
  sh /vagrant/scripts/02_install_os_packages.sh

  # Setup /etc/hosts & /etc/resolv.conf
  sh /vagrant/scripts/03_setup_hosts.sh

  # Setup chrony
  sh /vagrant/scripts/04_setup_chrony.sh

  # Setup shared disks
  BOX_DISK_NUM=$((BOX_DISK_NUM + 1))
  sh /vagrant/scripts/05_setup_shared_disks.sh $BOX_DISK_NUM virtualbox

  # Setup users
  sh /vagrant/scripts/06_setup_users.sh

  # Setup users password
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Set root, oracle and grid password"
  echo "-----------------------------------------------------------------"
  echo ${ROOT_PASSWORD}   | passwd --stdin root
  echo ${GRID_PASSWORD}   | passwd --stdin grid
  echo ${ORACLE_PASSWORD} | passwd --stdin oracle

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
  expect /vagrant/scripts/07_setup_user_equ.expect grid   ${GRID_PASSWORD}   ${NODE1_HOSTNAME} ${NODE1_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh
  expect /vagrant/scripts/07_setup_user_equ.expect oracle ${ORACLE_PASSWORD} ${NODE1_HOSTNAME} ${NODE1_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh

  # Install cvuqdisk package
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Install cvuqdisk package"
  echo "-----------------------------------------------------------------"
  yum install -y ${GI_HOME}/cv/rpm/cvuqdisk*.rpm

  # ---------------------------------------------------------------------
  # ---------------------------------------------------------------------
  if [ "${ASM_LIB_TYPE}" == "ASMFD" ]
  then
    # Setting-up asmfd disks label
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: ASMFD disks label setup"
    echo "-----------------------------------------------------------------"
    sh /vagrant/scripts/08_asmfd_label_disk.sh $BOX_DISK_NUM virtualbox
  else
    # Setting-up asmfd disks label
    echo "-----------------------------------------------------------------"
    echo -e "${INFO}`date +%F' '%T`: ASMLib disks label setup"
    echo "-----------------------------------------------------------------"
    sh /vagrant/scripts/08_asmlib_label_disk.sh $BOX_DISK_NUM virtualbox
  fi
  # ---------------------------------------------------------------------
  # ---------------------------------------------------------------------

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make GI install command"
  echo "-----------------------------------------------------------------"
  make_09_gi_installation ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure installation as 'RAC'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo "-----------------------------------------------------------------"
  su - grid -c 'sh /vagrant/scripts/09_gi_installation.sh'

  #-------------------------------------------------------
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Set root user equivalence"
  echo "-----------------------------------------------------------------"
  expect /vagrant/scripts/07_setup_user_equ.expect root ${ROOT_PASSWORD} ${NODE1_HOSTNAME} ${NODE1_HOSTNAME} ${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure setup"
  echo "-----------------------------------------------------------------"
  sh /vagrant/scripts/10_gi_setup.sh
  #-------------------------------------------------------

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Make GI config command"
  echo "-----------------------------------------------------------------"
  make_11_gi_config ;

  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Grid Infrastructure configuration as 'RAC'"
  echo -e "${INFO}`date +%F' '%T`: - ASM library   : ${ASM_LIB_TYPE}"
  echo "-----------------------------------------------------------------"
  su - grid -c 'sh /vagrant/scripts/11_gi_config.sh'
  #-------------------------------------------------------

  # Setup RHP Server
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Setup FPP Server"
  echo "-----------------------------------------------------------------"
  sh /vagrant/scripts/12_Setup_FPP.sh
fi

if [ `hostname` == "${VM2_NAME}" ]
then
  # Setting-up /u01 disk
  sh /vagrant/scripts/01_setup_u01.sh $BOX_DISK_NUM virtualbox
  
  # Install OS Pachages
  sh /vagrant/scripts/02_install_os_packages.sh
  
  # Setup /etc/hosts & /etc/resolv.conf
  sh /vagrant/scripts/03_setup_hosts.sh
  
  # Setup chrony
  sh /vagrant/scripts/04_setup_chrony.sh
    
  # Setup users
  sh /vagrant/scripts/06_setup_users.sh
  
  # Setup users password
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Set root, oracle and grid password"
  echo "-----------------------------------------------------------------"
  echo ${ROOT_PASSWORD}   | passwd --stdin root
  echo ${GRID_PASSWORD}   | passwd --stdin grid
  echo ${ORACLE_PASSWORD} | passwd --stdin oracle
fi

# run user-defined post-setup scripts
run_user_scripts;


#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


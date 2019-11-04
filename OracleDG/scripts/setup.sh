#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/setup.sh,v 2.0.1.1 2018/12/10 11:15:28 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      setup.sh
#
#    DESCRIPTION
#      Creates an Oracle RAC (Real Application Cluster) Vagrant virtual machine.
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton
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

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------

# build the setup.env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Make the setup.env"
echo "-----------------------------------------------------------------"

DB_MAJOR=$(echo "${DB_SOFTWARE_VER}" | cut -c1-2)
DB_MAINTENANCE=$(echo "${DB_SOFTWARE_VER}" | cut -c3)
DB_APP=$(echo "${DB_SOFTWARE_VER}" | cut -c4)
DB_COMP=$(echo "${DB_SOFTWARE_VER}" | cut -c5)
DB_VERSION=${DB_MAJOR}"."${DB_MAINTENANCE}"."${DB_APP}"."${DB_COMP}
DB_HOME="/u01/app/oracle/product/"$DB_VERSION"/dbhome_1"

  cat <<EOL > /vagrant_config/setup.env
#----------------------------------------------------------
# Env Variables
#----------------------------------------------------------
export PREFIX_NAME=$PREFIX_NAME
#----------------------------------------------------------
#----------------------------------------------------------
export DB_SOFTWARE=$DB_SOFTWARE
#----------------------------------------------------------
#----------------------------------------------------------
export DB_MAJOR=$DB_MAJOR
#----------------------------------------------------------
#----------------------------------------------------------
export SYS_PASSWORD=$SYS_PASSWORD
export PDB_PASSWORD=$PDB_PASSWORD
#----------------------------------------------------------
#----------------------------------------------------------
export DNS_PUBLIC_IP=$DNS_PUBLIC_IP
export NODE1_PUBLIC_IP=$NODE1_PUBLIC_IP
export NODE2_PUBLIC_IP=$NODE2_PUBLIC_IP
#----------------------------------------------------------
#----------------------------------------------------------
export DOMAIN_NAME=localdomain

export NODE1_HOSTNAME=${VM1_NAME}
export NODE2_HOSTNAME=${VM2_NAME}
export NODE1_FQ_HOSTNAME=\${NODE1_HOSTNAME}.\${DOMAIN_NAME}
export NODE2_FQ_HOSTNAME=\${NODE2_HOSTNAME}.\${DOMAIN_NAME}

export NODE1_PRIVNAME=\${NODE1_HOSTNAME}-priv
export NODE2_PRIVNAME=\${NODE2_HOSTNAME}-priv
export NODE1_FQ_PRIVNAME=\${NODE1_PRIVNAME}.\${DOMAIN_NAME}
export NODE2_FQ_PRIVNAME=\${NODE2_PRIVNAME}.\${DOMAIN_NAME}
#----------------------------------------------------------
#----------------------------------------------------------
export ORA_LANGUAGES=$ORA_LANGUAGES

export ORA_INVENTORY=/u01/app/oraInventory
export DB_BASE=/u01/app/oracle

export DB_HOME=${DB_HOME}
export DB_NAME=${DB_NAME}
export PDB_NAME=${PDB_NAME}
export CDB=${CDB}
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
. /vagrant_config/setup.env

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
# Install OS Pachages
sh /vagrant_scripts/01_install_os_packages.sh

# Setting-up /u01 disk
sh /vagrant_scripts/02_setup_u01.sh $BOX_DISK_NUM

# Setup shared disks
BOX_DISK_NUM=$((BOX_DISK_NUM + 1))
sh /vagrant_scripts/03_setup_oradata_disks.sh $BOX_DISK_NUM

# Setup /etc/hosts & /etc/resolv.conf
sh /vagrant_scripts/04_setup_hosts.sh

# Setup users
sh /vagrant_scripts/05_setup_users.sh

# Setup users password
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set root, oracle password"
echo "-----------------------------------------------------------------"
echo ${ROOT_PASSWORD}   | passwd --stdin root
echo ${ORACLE_PASSWORD} | passwd --stdin oracle

# Do RDBMS_software_installation.sh
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: RDBMS software install"
echo "-----------------------------------------------------------------"
su - oracle -c 'sh /vagrant_scripts/06_do_RDBMS_software_installation.sh'
sh ${ORA_INVENTORY}/orainstRoot.sh
sh ${DB_HOME}/root.sh

if [ "${DB_MAJOR}" == "12" ]
then
  rm -fr ${DB_HOME}/database
fi

# Oracle Net Setup
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Oracle Net setup"
echo "-----------------------------------------------------------------"
su - oracle -c 'sh /vagrant_scripts/07_setup_OracleNet.sh'

if [ `hostname` == ${NODE1_HOSTNAME} ]
then
  su - oracle -c 'sh /vagrant_scripts/primary_DB_setup.sh'
fi

if [ `hostname` == ${NODE2_HOSTNAME} ]
then
  su - oracle -c 'sh /vagrant_scripts/standby_DB_setup.sh'
fi

# Autostart
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup DB autostart"
echo "-----------------------------------------------------------------"
sh /vagrant_scripts/08_setup_autostart.sh

# run user-defined post-setup scripts
run_user_scripts;
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


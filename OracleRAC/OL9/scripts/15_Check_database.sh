#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      15_Check_database.sh
#
#    DESCRIPTION
#      Check database
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton - RAC Pack, Cloud Innovation and Solution Engineering Team
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     11/06/18 - Creation
#
#    REVISION
#    20240603 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env

export ORACLE_HOME=${DB_HOME}

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Config database"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/srvctl config database -d ${DB_NAME}

if [ $? -ne 0 ]
then
  if [ "${ORESTART}" == "true" ]
  then
    echo "-----------------------------------------------------------------------------------"
    echo -e "${ERROR}`date +%F' '%T`: Oracle Restart on Vagrant is having problems"
    echo "-----------------------------------------------------------------------------------"
  else
    echo "-----------------------------------------------------------------------------------"
    echo -e "${ERROR}`date +%F' '%T`: Oracle RAC on Vagrant is having problems"
    echo "-----------------------------------------------------------------------------------"
  fi
  exit
fi

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Database Status"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/srvctl status database -d ${DB_NAME}

if [ "${ORESTART}" == "true" ]
then
  echo "-----------------------------------------------------------------------------------"
  echo -e "${SUCCESS}`date +%F' '%T`: Oracle Restart on Vagrant has been created successfully!"
  echo "-----------------------------------------------------------------------------------"
else
  echo "-----------------------------------------------------------------------------------"
  echo -e "${SUCCESS}`date +%F' '%T`: Oracle RAC on Vagrant has been created successfully!"
  echo "-----------------------------------------------------------------------------------"
fi

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------



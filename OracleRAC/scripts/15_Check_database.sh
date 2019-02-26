#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/15_Check_database.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      15_Check_database.sh
#
#    DESCRIPTION
#      Check database
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
. /vagrant_config/setup.env
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



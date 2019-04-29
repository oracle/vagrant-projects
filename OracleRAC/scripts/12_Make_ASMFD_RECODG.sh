#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/12_Make_ASMFD_RECODG.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      12_Make_ASMFD_RECODG.sh
#
#    DESCRIPTION
#      Make RECO DG
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

export ORACLE_HOME=${GRID_HOME}
if [ "${ORESTART}" == "false" ]
then
  export ORACLE_SID=+ASM1
else
  export ORACLE_SID=+ASM
fi

DISKS_STRING=""
declare -a DEVICES
for device in /dev/ORCL_DISK*_p2
do
  DEVICES=("${dev[@]}" "$device")
  DISK=$(basename "$DEVICES")
  DISKS_STRING=${DISKS_STRING}"DISK '"${DEVICES}"' NAME "${DISK}" "
done

${GRID_HOME}/bin/sqlplus / as sysasm <<EOF
CREATE DISKGROUP RECO NORMAL REDUNDANCY 
 ${DISKS_STRING} 
 ATTRIBUTE 
   'compatible.asm'='18.3.0.0', 
   'compatible.rdbms'='11.2.0.4',
   'sector_size'='512',
   'AU_SIZE'='4M',
   'content.type'='recovery';
EOF
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

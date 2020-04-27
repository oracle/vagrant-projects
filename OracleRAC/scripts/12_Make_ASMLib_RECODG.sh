#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/12_Make_ASMLib_RECODG.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      12_Make_ASMLib_RECODG.sh
#
#    DESCRIPTION
#      Make RECO DG
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
. /vagrant_config/setup.env
export ORACLE_HOME=${GI_HOME}
if [ "${ORESTART}" == "false" ]
then
  export ORACLE_SID=+ASM1
else
  export ORACLE_SID=+ASM
fi

DISKS_STRING=""
declare -a DEVICES
for device in /dev/oracleasm/disks/ORCL_DISK*_P2
do
  DEVICES=("${dev[@]}" "$device")
  DISK=$(basename "$DEVICES")
  DISKS_STRING=${DISKS_STRING}"DISK '"${DEVICES}"' NAME "${DISK}" "
done

${GI_HOME}/bin/sqlplus / as sysasm <<EOF
CREATE DISKGROUP RECO NORMAL REDUNDANCY 
 ${DISKS_STRING}
 ATTRIBUTE 
   'compatible.asm'='${GI_VERSION}', 
   'compatible.rdbms'='${DB_VERSION}',
   'sector_size'='512',
   'AU_SIZE'='4M',
   'content.type'='recovery';
EOF
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

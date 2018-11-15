#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/12_Make_ASMFD_RECODG.sh,v 2.0.1.1 2018/11/14 13:53:55 rcitton Exp $
#
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      12_Make_ASMFD_RECODG.sh
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
export ORACLE_HOME=${GRID_HOME}
if [ "${ORESTART}" == "false" ]
then
  export ORACLE_SID=+ASM1
else
  export ORACLE_SID=+ASM
fi
${GRID_HOME}/bin/sqlplus / as sysasm <<EOF
CREATE DISKGROUP RECO NORMAL REDUNDANCY 
 DISK '/dev/ORCL_DISK1_P2' NAME ORCL_DISK1_P2 
 DISK '/dev/ORCL_DISK2_P2' NAME ORCL_DISK2_P2 
 DISK '/dev/ORCL_DISK3_P2' NAME ORCL_DISK3_P2 
 DISK '/dev/ORCL_DISK4_P2' NAME ORCL_DISK4_P2 
 ATTRIBUTE 
   'compatible.asm'='18.3.0.0', 
   'compatible.rdbms'='11.2.0.2',
   'sector_size'='512',
   'AU_SIZE'='4M',
   'content.type'='recovery',
   'compatible.advm'='18.3.0.0';
EOF
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

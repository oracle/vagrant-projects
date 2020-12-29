#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
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
#       Ruggero Citton - RAC Pack, Cloud Innovation and Solution Engineering Team
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     11/06/18 - Creation
#
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env

export ORACLE_HOME=${GI_HOME}
if [ "${ORESTART}" == "false" ]
then
  export ORACLE_SID=+ASM1
else
  export ORACLE_SID=+ASM
fi

  DISKS_STRING="DISK "
  for device in `(cd /dev/oracleafd/disks; ls ORCL_DISK*_P2)`
  do
    AFDDISK="AFD:${device}"
    DISKS_STRING=${DISKS_STRING}"'$AFDDISK',"
  done
    DISKS_STRING="${DISKS_STRING::-1}"

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

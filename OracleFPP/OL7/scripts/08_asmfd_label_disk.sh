#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      08_asmfd_label_disk.sh
#
#    DESCRIPTION
#      Setup ASMFD disks
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
. /vagrant/config/setup.env
BOX_DISK_NUM=$1
PROVIDER=$2

if [ "${PROVIDER}" == "libvirt" ]; then
  DEVICE="vd"
elif [ "${PROVIDER}" == "virtualbox" ]; then
  DEVICE="sd"
else
  echo "Not supported provider: ${PROVIDER}"
  exit 1
fi

export ORACLE_HOME=${GI_HOME}
export ORACLE_BASE=/tmp

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  DISK="ORCL_DISK${i}_P1"
  DEVICE_PATH="/dev/${DEVICE}${LETTER}1";
  ${GI_HOME}/bin/asmcmd afd_label ${DISK} ${DEVICE_PATH} --init
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

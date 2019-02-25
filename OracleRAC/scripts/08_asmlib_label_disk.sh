#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/08_asmlib_label_disk.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      08_asmlib_label_disk.sh
#
#    DESCRIPTION
#      Setup ASMLib disks
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
/usr/sbin/oracleasm configure -u grid -g asmadmin -e -b -s y
/usr/sbin/oracleasm init

BOX_DISK_NUM=$1
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  DISK="ORCL_DISK${i}_P1"
  DEVICE="/dev/sd${LETTER}1";
  /usr/sbin/oracleasm createdisk ${DISK} ${DEVICE}
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

BOX_DISK_NUM=$1
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  DISK="ORCL_DISK${i}_P2"
  DEVICE="/dev/sd${LETTER}2";
  /usr/sbin/oracleasm createdisk ${DISK} ${DEVICE}
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

/usr/sbin/oracleasm scandisks
/usr/sbin/oracleasm listdisks

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

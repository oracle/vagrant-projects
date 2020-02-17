#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_fpp-2.0.1/scripts/08_asmlib_label_disk.sh,v 2.0.1.2 2020/02/17 12:19:54 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      08_asmlib_label_disk.sh
#
#    DESCRIPTION
#      Setup ASMLib disks
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     10/01/19 - Creation
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

/usr/sbin/oracleasm scandisks
/usr/sbin/oracleasm listdisks

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

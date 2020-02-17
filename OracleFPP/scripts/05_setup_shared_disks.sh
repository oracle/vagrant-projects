#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_fpp-2.0.1/scripts/05_setup_shared_disks.sh,v 2.0.1.2 2020/02/17 12:19:54 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      05_setup_shared_disks.sh 
#
#    DESCRIPTION
#      Setting-up shared disks partions & udev rules
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     10/01/19 - Creation
##
. /vagrant_config/setup.env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks partions"
echo "-----------------------------------------------------------------"
BOX_DISK_NUM=$1

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  parted /dev/sd${LETTER} --script -- mklabel gpt mkpart primary 4096s 100%
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks udev rules"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  echo "KERNEL==\"sd${LETTER}\",  SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK${i}\"    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  echo "KERNEL==\"sd${LETTER}1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK${i}_p1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Shared partprobe"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  /sbin/partprobe /dev/sd${LETTER}1
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done
sleep 10
/sbin/udevadm control --reload-rules
sleep 10
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  /sbin/partprobe /dev/sd${LETTER}1
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done
sleep 10
/sbin/udevadm control --reload-rules

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


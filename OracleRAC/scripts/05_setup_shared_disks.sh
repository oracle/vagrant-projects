#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/05_setup_shared_disks.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      05_setup_shared_disks.sh 
#
#    DESCRIPTION
#      Setting-up shared disks partions & udev rules
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
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks partions"
echo "-----------------------------------------------------------------"
BOX_DISK_NUM=$1
if [[ `hostname` == ${NODE2_HOSTNAME} || (`hostname` == ${NODE1_HOSTNAME} && "${ORESTART}" == "true") ]]
then
  LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
  SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
  for (( i=1; i<=$SDISKSNUM; i++ ))
  do
    parted /dev/sd${LETTER} --script -- mklabel gpt mkpart primary 4096s ${P1_RATIO}%
    parted /dev/sd${LETTER} --script -- mkpart primary ${P1_RATIO}% 100%
    LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
  done
fi

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks udev rules"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  echo "KERNEL==\"sd${LETTER}\",  SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK${i}\"    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  echo "KERNEL==\"sd${LETTER}1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK${i}_p1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  echo "KERNEL==\"sd${LETTER}2\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK${i}_p2\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
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
  /sbin/partprobe /dev/sd${LETTER}2
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
  /sbin/partprobe /dev/sd${LETTER}2
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done
sleep 10
/sbin/udevadm control --reload-rules

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


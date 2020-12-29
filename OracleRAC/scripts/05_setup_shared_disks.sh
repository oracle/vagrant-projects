#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
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
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks partions"
echo "-----------------------------------------------------------------"
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

if [[ `hostname` == ${NODE2_HOSTNAME} || (`hostname` == ${NODE1_HOSTNAME} && "${ORESTART}" == "true") ]]
then
  LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
  SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
  for (( i=1; i<=$SDISKSNUM; i++ ))
  do
    parted /dev/${DEVICE}${LETTER} --script -- mklabel gpt mkpart primary 4096s ${P1_RATIO}%
    parted /dev/${DEVICE}${LETTER} --script -- mkpart primary ${P1_RATIO}% 100%
    LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
  done
fi

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks udev rules"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  echo "KERNEL==\"sd?\",  ENV{ID_SERIAL}==\"`udevadm info --query=all --name=/dev/${DEVICE}${LETTER} | grep ID_SERIAL= | awk -F "=" '{print $2}'`\", SYMLINK+=\"ORCL_DISK${i}\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  echo "KERNEL==\"sd?1\", ENV{ID_SERIAL}==\"`udevadm info --query=all --name=/dev/${DEVICE}${LETTER} | grep ID_SERIAL= | awk -F "=" '{print $2}'`\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  echo "KERNEL==\"sd?2\", ENV{ID_SERIAL}==\"`udevadm info --query=all --name=/dev/${DEVICE}${LETTER} | grep ID_SERIAL= | awk -F "=" '{print $2}'`\", SYMLINK+=\"ORCL_DISK${i}_p2\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Shared partprobe"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  /sbin/partprobe /dev/${DEVICE}${LETTER}1
  /sbin/partprobe /dev/${DEVICE}${LETTER}2
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done
sleep 10
/sbin/udevadm control --reload-rules
sleep 10
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  /sbin/partprobe /dev/${DEVICE}${LETTER}1
  /sbin/partprobe /dev/${DEVICE}${LETTER}2
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done
sleep 10
/sbin/udevadm control --reload-rules

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


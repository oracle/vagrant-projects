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
#    20240631 - $Revision: 2.0.2.1 $
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

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  parted /dev/${DEVICE}${LETTER} --script -- mklabel gpt mkpart primary 4096s 100%
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up shared disks udev rules"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
if [ "${PROVIDER}" == "libvirt" ]; then
  for (( i=1; i<=$SDISKSNUM; i++ ))
  do
    echo "KERNEL==\"${DEVICE}${LETTER}\",  SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", ENV{ID_PART_TABLE_TYPE}==\"gpt\", SYMLINK+=\"ORCL_DISK${i}\"   , OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
    echo "KERNEL==\"${DEVICE}${LETTER}1\", SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", ENV{ID_PART_ENTRY_NUMBER}==\"1\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
    LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
  done
elif [ "${PROVIDER}" == "virtualbox" ]; then
  for (( i=1; i<=$SDISKSNUM; i++ ))
  do
    echo "KERNEL==\"${DEVICE}${LETTER}\",  ENV{ID_SERIAL}==\"`udevadm info --query=all --name=/dev/${DEVICE}${LETTER} | grep ID_SERIAL= | awk -F "=" '{print $2}'`\", SYMLINK+=\"ORCL_DISK${i}\",    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
    echo "KERNEL==\"${DEVICE}${LETTER}1\", ENV{ID_SERIAL}==\"`udevadm info --query=all --name=/dev/${DEVICE}${LETTER} | grep ID_SERIAL= | awk -F "=" '{print $2}'`\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
    LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
  done
fi
/sbin/udevadm control --reload-rules

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Shared partprobe"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  /sbin/partx -u /dev/${DEVICE}${LETTER}1

  chown grid:asmadmin /dev/${DEVICE}${LETTER}
  chown grid:asmadmin /dev/${DEVICE}${LETTER}1
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


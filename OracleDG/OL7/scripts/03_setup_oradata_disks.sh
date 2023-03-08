#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      03_setup_oradata_disks.sh 
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
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     11/06/18 - Creation
# 
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up oradata disks partions"
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
echo -e "${INFO}`date +%F' '%T`: Making the LVM Group"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/${DEVICE}[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  pvcreate /dev/${DEVICE}${LETTER}1
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKS=$(ls /dev/${DEVICE}[${LETTER}-z]1)
vgcreate VolGroupOra ${SDISKS}

lvcreate -l 100%FREE -n LogVolData VolGroupOra

# Make XFS
mkfs.xfs -f /dev/VolGroupOra/LogVolData

# Set fstab
UUID=`blkid -s UUID -o value /dev/VolGroupOra/LogVolData`
mkdir -p /u02
cat >> /etc/fstab <<EOF
UUID=${UUID}  /u02    xfs    defaults 1 2
EOF

# Mount
mount /u02

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


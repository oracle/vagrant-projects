#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/03_setup_oradata_disks.sh,v 2.0.1.1 2018/11/18 23:12:36 rcitton Exp $
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
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up oradata disks partions"
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
echo -e "${INFO}`date +%F' '%T`: Making the LVM Group"
echo "-----------------------------------------------------------------"
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKSNUM=$(ls -l /dev/sd[${LETTER}-z]|wc -l)
for (( i=1; i<=$SDISKSNUM; i++ ))
do
  pvcreate /dev/sd${LETTER}1
  LETTER=$(echo "$LETTER" | tr "0-9a-z" "1-9a-z_")
done

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
SDISKS=$(ls /dev/sd[${LETTER}-z]1)
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


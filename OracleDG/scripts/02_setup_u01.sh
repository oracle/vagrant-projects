#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/02_setup_u01.sh,v 2.0.1.2 2018/11/19 14:19:19 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      01_setup_u01.sh
#
#    DESCRIPTION
#      Setup for u01
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
echo -e "${INFO}`date +%F' '%T`: Setting-up /u01 disk"
echo "-----------------------------------------------------------------"
# Single GPT partition for the whole disk
BOX_DISK_NUM=$1
LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
parted -s -a optimal /dev/sd${LETTER} mklabel gpt -- mkpart primary 2048s 100%

# LVM setup
pvcreate /dev/sd${LETTER}1
vgcreate VolGroupU01 /dev/sd${LETTER}1
lvcreate -l 100%FREE -n LogVolU01 VolGroupU01

# Make XFS
mkfs.xfs -f /dev/VolGroupU01/LogVolU01

# Set fstab
UUID=`blkid -s UUID -o value /dev/VolGroupU01/LogVolU01`
mkdir -p /u01
cat >> /etc/fstab <<EOF
UUID=${UUID}  /u01    xfs    defaults 1 2
EOF

# Mount
mount /u01
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/01_setup_u01.sh,v 2.0.1.1 2018/11/14 13:53:54 rcitton Exp $
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
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up /u01 disk"
echo "-----------------------------------------------------------------"
# Single GPT partition for the whole disk
parted -s -a optimal /dev/sdc mklabel gpt -- mkpart primary xfs 2048s -0

# Make XFS
mkfs.xfs -f /dev/sdc1

# Set fstab
UUID=`blkid -s UUID -o value /dev/sdc1`
mkdir -p /u01
cat >> /etc/fstab <<EOF
UUID=${UUID}  /u01    xfs    defaults 1 2
EOF

# Mount
mount /u01

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

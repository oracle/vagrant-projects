#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: August, 2022
# Author: simon.coter@oracle.com
# Description: Updates Oracle Linux to the latest version
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Started up'

# get up to date
sudo dnf upgrade -y

echo 'INSTALLER: System updated'

echo 'INSTALLER: allow ssh access by password'
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl reload sshd.service

# fix locale warning
cat <<EOF | sudo tee -a /etc/environment
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

echo 'INSTALLER: Locale set'

echo 'INSTALLER: Creating persistent virtual-disk /dev/sdb1'
# persistent disk. check if xfs fs already exists
if ! sudo blkid /dev/sdb1 | grep -q "TYPE=\"xfs\""; then
    printf "o\nn\np\n1\n\n\nw\n" |sudo fdisk /dev/sdb
    sudo mkfs.xfs /dev/sdb1
fi
sudo mkdir -p /var/yum
sudo mount /dev/sdb1 /var/yum
sudo chown vagrant: /var/yum

echo 'INSTALLER: Add entry for the 2nd virtual-disk into /etc/fstab'
cat /etc/mtab |grep sdb1 |sudo tee -a /etc/fstab

echo 'INSTALLER: Installing prerequisite packages'
sudo dnf install -y httpd
sudo dnf install -y oracle-olcne-release-el8
sudo dnf config-manager --enable ol8_olcne16 ol8_addons ol8_baseos_latest ol8_appstream ol8_UEKR7
sudo dnf config-manager --disable ol8_olcne15 ol8_olcne14 ol8_olcne13 ol8_olcne12
sudo systemctl enable --now firewalld.service
sudo firewall-cmd --add-service=http --permanent
# sudo firewall-cmd --add-service=https --permanent
sudo systemctl reload firewalld.service
sudo systemctl enable --now httpd.service

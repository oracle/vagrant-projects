#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: August, 2022
# Author: simon.coter@oracle.com
# Description: Setup the Yum mirror configuration
# Manual steps avaialble at https://docs.oracle.com/en/learn/local_yum-mirror_linux_8/index.html#introduction
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'YUM MIRROR SETUP: Started up'

# Software Install

dnf install -y yum-utils
dnf install -y httpd
dnf install -y oracle-olcne-release-el8
dnf install net-tools -y
dnf install mlocate -y
dnf config-manager --enable ol8_olcne15 ol8_baseos_latest ol8_appstream ol8_addons ol8_UEKR6
dnf config-manager --disable ol8_olcne12 ol8_olcne13 ol8_olcne14
systemctl enable --now httpd.service
systemctl enable --now firewalld.service
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# system configuration - yum mirror

printf "o\nn\np\n1\n\n\nw\n" |fdisk /dev/sdb
mkfs.xfs /dev/sdb1
mkdir -p /var/yum
mount /dev/sdb1 /var/yum
ln -s /var/yum /var/www/html/yum
dnf install -y policycoreutils-python-utils
#/usr/sbin/semanage fcontext -a -t httpd_sys_content_t "/var/yum(/.*)?"
restorecon -F -R -v /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_baseos_latest --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_appstream --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_olcne15 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_addons --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_UEKR6 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
sudo /usr/bin/reposync --delete --newest-only --repoid ol8_UEKR7 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum

# add sync script for yum mirror
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_baseos_latest --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" > /home/vagrant/sync-yum.sh
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_appstream --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" >> /home/vagrant/sync-yum.sh
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_olcne15 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" >> /home/vagrant/sync-yum.sh
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_addons --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" >> /home/vagrant/sync-yum.sh
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_UEKR6 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" >> /home/vagrant/sync-yum.sh
echo "sudo /usr/bin/reposync --delete --newest-only --repoid ol8_UEKR7 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum" >> /home/vagrant/sync-yum.sh
chown vagrant:vagrant /home/vagrant/sync-yum.sh
chmod 755 /home/vagrant/sync-yum.sh

echo 'YUM MIRROR SETUP: Completed'

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
sudo dnf install -y yum-utils
sudo dnf install -y net-tools mlocate
sudo firewall-cmd --reload

# system configuration - yum mirror
sudo ln -s /var/yum /var/www/html/yum
sudo /usr/sbin/semanage fcontext -a -t httpd_sys_content_t "/var/yum(/.*)?"
sudo restorecon -F -R -v /var/yum

# add sync script for yum mirror
cat <<EOF | tee /home/vagrant/sync-yum.sh
/usr/bin/reposync --delete --newest-only --repoid ol8_baseos_latest --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
/usr/bin/reposync --delete --newest-only --repoid ol8_appstream --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
/usr/bin/reposync --delete --newest-only --repoid ol8_olcne16 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
/usr/bin/reposync --delete --newest-only --repoid ol8_addons --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
/usr/bin/reposync --delete --newest-only --repoid ol8_UEKR6 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
/usr/bin/reposync --delete --newest-only --repoid ol8_UEKR7 --download-metadata --exclude='*.src,*.nosrc' -p /var/yum
EOF
chmod 700 /home/vagrant/sync-yum.sh

/home/vagrant/sync-yum.sh

echo 'YUM MIRROR SETUP: Completed'

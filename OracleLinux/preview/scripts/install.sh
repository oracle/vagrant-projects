#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: October, 2018
# Author: simon.coter@oracle.com
# Description: Updates Oracle Linux to the latest version
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Started up'

# get up to date

echo 'INSTALLER: Adding Oracle Linux 7 Update 6 Preview Channels'

cat >> /etc/yum.repos.d/public-yum-ol7.repo <<EOF 
[ol7_u6_developer]
name=Oracle Linux $releasever Update 6 installation media copy (x86_64)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL7/6/developer/x86_64/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1

[ol7_u6_developer_optional]
name=Oracle Linux $releasever Update 6 optional packages (x86_64)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL7/optional/developer/x86_64/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1

EOF

echo 'INSTALLER: Adding UEK5 Preview Channel'

cat >> /etc/yum.repos.d/public-yum-ol7.repo <<EOF
[ol7_uek5_preview]
name=Oracle Linux $releasever UEK5 Preview  (x86_64)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL7/optional/developer/x86_64/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF

echo 'INSTALLER: Getting the system updated'
yum remove kmod-vboxguest-uek5 -y
yum upgrade -y
yum install kernel-uek-devel bzip2 -y

echo 'INSTALLER: Getting VBox Guest Additions Installed'

wget https://www.virtualbox.org/download/testcase/VBoxGuestAdditions_5.2.21-125885.iso -o /dev/null
mount ./VBoxGuestAdditions_5.2.21-125885.iso /media
export KERN_VER=`ls /lib/modules |tail -1`
/media/VBoxLinuxAdditions.run

echo 'INSTALLER: Cleaning up installation files'
umount /media
rm -f ./VBoxGuestAdditions_5.2.21-125885.iso

echo 'INSTALLER: System updated'

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: Going to reboot to get updated system'

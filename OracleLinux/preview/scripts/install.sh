#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: simon.coter@oracle.com
# Description: Updates Oracle Linux to the latest 7.5 Preview version
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Started up'

echo 'Setup Oracle Linux 7.5 Preview Yum Channels'
echo '' >> /etc/yum.repos.d/public-yum-ol7.repo
echo '[ol7_u5_developer]' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'name=Oracle Linux $releasever Update 5 installation media copy ($basearch)' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'baseurl=http://yum.oracle.com/repo/OracleLinux/OL7/5/developer/$basearch/' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'enabled=1' >> /etc/yum.repos.d/public-yum-ol7.repo
echo '' >> /etc/yum.repos.d/public-yum-ol7.repo
echo '[ol7_u5_developer_optional]' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'name=Oracle Linux $releasever Update 5 optional packages ($basearch)' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'baseurl=http://yum.oracle.com/repo/OracleLinux/OL7/optional/developer/$basearch/' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'enabled=1' >> /etc/yum.repos.d/public-yum-ol7.repo
echo '' >> /etc/yum.repos.d/public-yum-ol7.repo
echo '[ol7_developer_UEKR5]' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'name=Oracle Linux $releasever UEK5 Development Packages ($basearch)' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'baseurl=http://yum.oracle.com/repo/OracleLinux/OL7/developer_UEKR5/$basearch/' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/public-yum-ol7.repo
echo 'enabled=1' >> /etc/yum.repos.d/public-yum-ol7.repo

# get up to date
echo 'Getting OL 7.5 Preview Updates.....'
yum upgrade -y

# update motd for Oracle Linux 7.5 Preview
echo '' > /etc/motd
echo 'Welcome to Oracle Linux Server release 7.5 Preview' >> /etc/motd
echo '' >> /etc/motd
echo 'The Oracle Linux End-User License Agreement can be viewed here:' >> /etc/motd
echo '' >> /etc/motd
echo '    * /usr/share/eula/eula.en_US' >> /etc/motd
echo '' >> /etc/motd
echo 'For additional packages, updates, documentation and community help, see:' >> /etc/motd
echo '' >> /etc/motd
echo '    * http://yum.oracle.com/' >> /etc/motd
echo '' >> /etc/motd

# install kmod rpms guest-add
# echo 'Installing VirtualBox Guest Additions - RPMs for Oracle Linux'
# yum install kmod-vboxguest-uek5-5.2.8-1.el7.x86_64 vboxguest-tools-5.2.8-1.el7.x86_64 -y

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: System updated'

echo 'INSTALLER: Upgrading VirtualBox Guest Additions to 5.2 for UEK5'
echo ''
echo 'INSTALLER: Getting required dependencies...'
yum install bzip2 kernel-uek-devel -y
wget https://download.virtualbox.org/virtualbox/5.2.8/VBoxGuestAdditions_5.2.8.iso -O /tmp/VBoxGuestAdditions_5.2.8.iso -o /tmp/vboxguestadd-download.log

echo 'INSTALLER: Installing VirtualBox Guest Additions 5.2.8...'
mount -o loop /tmp/VBoxGuestAdditions_5.2.8.iso /media
/media/VBoxLinuxAdditions.run

echo 'INSTALLER: Compiling VirtualBox Modules for UEK5 Kernel...'
echo 'export KERN_VER=`ls /lib/modules |grep 4.14`' > /tmp/compile_vboxga_uek5.sh
echo '/sbin/rcvboxadd setup' >> /tmp/compile_vboxga_uek5.sh
chmod 700 /tmp/compile_vboxga_uek5.sh
/tmp/compile_vboxga_uek5.sh
rm -f /tmp/compile_vboxga_uek5.sh

echo 'INSTALLER: Cleaning up installation...'
umount /media
rm -f /tmp/VBoxGuestAdditions_5.2.8.iso

echo 'INSTALLER: Going to reboot to get updated system with UEK5'

#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: April, 2018
# Author: simon.coter@oracle.com
# Description: Updates Oracle Linux to the latest 7 with UEK5 Preview
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Started up'

echo 'Setup Oracle Linux Preview Yum Channels'
cat >> /etc/yum.repos.d/public-yum-ol7.repo << EOF

[ol7_uek5_preview]
name=Oracle Linux $releasever UEK5 Preview ($basearch)
baseurl=https://yum.oracle.com/repo/OracleLinux/OL7/developer_UEKR5/x86_64/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1

EOF

# get up to date
echo 'Getting OL 7 - UEK5 Preview Updates.....'
yum upgrade -y

echo 'Getting grub.cfg correctly populated.....'
grub2-mkconfig > /boot/grub2/grub.cfg

# update motd for Oracle Linux 7 + UEK5 Preview
cat > /etc/motd << EOF

Welcome to Oracle Linux Server release 7 UEK5 Preview

The Oracle Linux End-User License Agreement can be viewed here:

    * /usr/share/eula/eula.en_US

For additional packages, updates, documentation and community help, see:

    * http://yum.oracle.com/

EOF

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: System updated'

echo 'INSTALLER: Upgrading VirtualBox Guest Additions to 5.2 for UEK5'
echo ''
echo 'INSTALLER: Getting required dependencies...'
yum install bzip2 kernel-uek-devel -y
wget https://download.virtualbox.org/virtualbox/5.2.10/VBoxGuestAdditions_5.2.10.iso -O /tmp/VBoxGuestAdditions_5.2.10.iso -o /tmp/vboxguestadd-download.log

echo 'INSTALLER: Installing VirtualBox Guest Additions 5.2.10...'
mount -o loop /tmp/VBoxGuestAdditions_5.2.10.iso /media
/media/VBoxLinuxAdditions.run

echo 'INSTALLER: Compiling VirtualBox Modules for UEK5 Kernel...'
echo 'export KERN_VER=`ls /lib/modules |grep "^4.14"`' > /tmp/compile_vboxga_uek5.sh
echo '/sbin/rcvboxadd setup' >> /tmp/compile_vboxga_uek5.sh
chmod 700 /tmp/compile_vboxga_uek5.sh
/tmp/compile_vboxga_uek5.sh
rm -f /tmp/compile_vboxga_uek5.sh

echo 'INSTALLER: Cleaning up installation...'
umount /media
rm -f /tmp/VBoxGuestAdditions_5.2.10.iso

echo 'INSTALLER: Going to reboot to get updated system with UEK5'

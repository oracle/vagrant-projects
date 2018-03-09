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

echo 'Optional - Add Proxy to Yum configuration'
#echo 'proxy=http://<Proxy-Server-IP-Address>:<Proxy_Port>' >> /etc/yum.conf
#echo 'proxy_username=<Proxy-User-Name>' >> /etc/yum.conf
#echo 'proxy_password=<Proxy-Password>' >> /etc/yum.conf

# get up to date
echo 'Getting OL 7.5 Preview Updates.....'
yum upgrade -y

# install kmod rpms guest-add
echo 'Installing VirtualBox Guest Additions - RPMs for Oracle Linux'
#yum install kmod-vboxguest-uek5-5.2.8-1.el7.x86_64 vboxguest-tools-5.2.8-1.el7.x86_64 -y

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: System updated'
echo 'INSTALLER: Going to reboot to get updated system'
reboot

echo 'INSTALLER: Installation complete, Oracle Linux ready to use!'

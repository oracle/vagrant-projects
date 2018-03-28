#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: gerald.venzl@oracle.com
# Description: Updates Oracle Linux to the latest version
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Started up'

# get yum-config-manager to enable/disable repo
yum install -y yum-utils.noarch

# enable UEK4 latest repo
yum-config-manager --enable ol6_UEKR4

# disable UEK(2) latest repo
yum-config-manager --disable ol6_UEK_latest

# fix /etc/dracut.conf.d/01-dracut-vm.conf configuration file
echo 'add_drivers+=" xen_netfront xen_blkfront "' > /etc/dracut.conf.d/01-dracut-vm.conf
echo 'add_drivers+=" virtio_blk virtio_net virtio virtio_pci virtio_balloon "' >> /etc/dracut.conf.d/01-dracut-vm.conf
echo 'add_drivers+=" hyperv_keyboard hv_netvsc hid_hyperv hv_utils hv_storvsc hyperv_fb "' >> /etc/dracut.conf.d/01-dracut-vm.conf
echo 'add_drivers+=" ahci libahci "' >> /etc/dracut.conf.d/01-dracut-vm.conf

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: Going to reboot to get updated system'

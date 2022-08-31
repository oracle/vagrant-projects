#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2022 Oracle and/or its affiliates. All rights reserved.
#
# Since: August, 2022
# Author: simon.coter@oracle.com
# Description: Setup the Oracle Container Registry Mirror
# Manual steps avaialble at https://docs.oracle.com/en/operating-systems/oracle-linux/podman/podman-UsingContainerRegistries.html#podman-ocr-local-mirror
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'OCR MIRROR SETUP: Started up'

# Software Install & system configuration
dnf install podman -y
dnf install openssl -y
firewall-cmd --zone=public --permanent --add-port=5001/tcp
systemctl restart firewalld
dnf install olcne-utils -y

# disable SELINUX
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# system configuration - ocr mirror
openssl req -x509 -newkey rsa:4096 -keyout /tmp/ocr-yum-mirror.key -nodes -out /tmp/ocr-yum-mirror.crt -sha256 -subj '/CN=ocr-yum-mirror' -addext "subjectAltName = DNS:ocr-yum-mirror" -days 3650
mkdir -p /var/yum/registry
ln -s /var/yum/registry /var/lib/registry
mkdir -p /var/lib/registry/conf.d
cp /tmp/ocr-yum-mirror.crt /var/lib/registry/conf.d/
cp /tmp/ocr-yum-mirror.key /var/lib/registry/conf.d/
cp /tmp/ocr-yum-mirror.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
chmod 600 /var/lib/registry/conf.d/ocr-yum-mirror.key

# start container-registry mirror container
podman run -d -p 5000:5000 --name ocr-yum-mirror --restart=always \
    -v /var/lib/registry:/registry_data \
    -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registry_data \
    -e REGISTRY_HTTP_TLS_KEY=/registry_data/conf.d/ocr-yum-mirror.key \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/registry_data/conf.d/ocr-yum-mirror.crt \
    -e REGISTRY_AUTH="" \
    container-registry.oracle.com/os/registry:v2.7.1.1

# collect OCNE container images
registry-image-helper.sh --to ocr-yum-mirror:5000/olcne

# add sync script for OCR mirror
echo "sudo registry-image-helper.sh --to ocr-yum-mirror:5000/olcne" > /home/vagrant/sync-ocr.sh
chown vagrant:vagrant /home/vagrant/sync-ocr.sh
chmod 755 /home/vagrant/sync-ocr.sh

echo 'OCR MIRROR SETUP: Completed'

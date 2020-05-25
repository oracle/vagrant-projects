#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      03_setup_hosts.sh
#
#    DESCRIPTION
#      Setup for '/etc/hosts'
#
#    NOTES
#      DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#      ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     10/01/19 - Creation
#
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup /etc/hosts"
echo "-----------------------------------------------------------------"

cat > /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

cat >> /etc/hosts <<EOF
# Public host info
${NODE1_PUBLIC_IP}  ${NODE1_FQ_HOSTNAME}  ${NODE1_HOSTNAME}
${NODE2_PUBLIC_IP}  ${NODE2_FQ_HOSTNAME}  ${NODE2_HOSTNAME}
# Private host info
${NODE1_PRIV_IP}  ${NODE1_FQ_PRIVNAME}   ${NODE1_PRIVNAME}
${NODE2_PRIV_IP}  ${NODE2_FQ_PRIVNAME}   ${NODE2_PRIVNAME}
# Virtual host info
${NODE1_VIP_IP}  ${NODE1_FQ_VIPNAME}    ${NODE1_VIPNAME}
${NODE2_VIP_IP}  ${NODE2_FQ_VIPNAME}    ${NODE2_VIPNAME}
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup SCAN on /etc/hosts"
echo "-----------------------------------------------------------------"
cat >> /etc/hosts <<EOF
# SCAN
${SCAN_IP1}    ${FQ_SCAN_NAME}    ${SCAN_NAME}
${SCAN_IP2}    ${FQ_SCAN_NAME}    ${SCAN_NAME}
${SCAN_IP3}    ${FQ_SCAN_NAME}    ${SCAN_NAME}
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup /etc/resolv.conf"
echo "-----------------------------------------------------------------"
cat > /etc/resolv.conf <<EOF
search ${DOMAIN_NAME}
nameserver ${DNS_PUBLIC_IP}
EOF

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

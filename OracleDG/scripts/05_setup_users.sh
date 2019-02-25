#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/05_setup_users.sh,v 2.0.1.1 2018/11/18 23:12:36 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      06_setup_users.sh
#
#    DESCRIPTION
#      Setup oracle & grid users
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
. /vagrant_config/setup.env

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup oracle user"
echo "-----------------------------------------------------------------"
userdel -fr oracle
groupdel oinstall
groupdel dba
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel racdba
groupadd -g 1001 oinstall
groupadd -g 1002 dbaoper
groupadd -g 1003 dba
groupadd -g 1007 backupdba
groupadd -g 1008 dgdba
groupadd -g 1009 kmdba
groupadd -g 1010 racdba
useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g 1001 -G 1002,1003,1007,1008,1009,1010

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set oracle limits"
echo "-----------------------------------------------------------------"
cat << EOL >> /etc/security/limits.conf
# Oracle user
oracle soft nofile 131072
oracle hard nofile 131072
oracle soft nproc 131072
oracle hard nproc 131072
oracle soft core unlimited
oracle hard core unlimited
oracle soft memlock 98728941
oracle hard memlock 98728941
oracle soft stack 10240
oracle hard stack 32768
EOL

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Create DB_HOME directories"
echo "-----------------------------------------------------------------"
mkdir -p ${DB_BASE}
mkdir -p ${DB_HOME}
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01/app
chown -R oracle:oinstall /u02/oradata
chmod -R ug+rw /u01
chmod -R ug+rw /u02

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set user env"
echo "-----------------------------------------------------------------"
if [ `hostname` == ${VM1_NAME} ]
then
  cat >> /home/oracle/.bash_profile << EOF
export ORACLE_HOME=${DB_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
export ORACLE_SID=${DB_NAME}
EOF
fi

if [ `hostname` == ${VM2_NAME} ]
then
  cat >> /home/oracle/.bash_profile << EOF
export ORACLE_HOME=${DB_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
export ORACLE_SID=${DB_NAME}
EOF
fi

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/06_setup_users.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
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
echo -e "${INFO}`date +%F' '%T`: Setup oracle and grid user"
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
groupadd -g 1004 asmadmin
groupadd -g 1005 asmoper
groupadd -g 1006 asmdba
groupadd -g 1007 backupdba
groupadd -g 1008 dgdba
groupadd -g 1009 kmdba
groupadd -g 1010 racdba
useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g 1001 -G 1002,1003,1006,1007,1008,1009,1010
useradd grid   -d /home/grid   -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g 1001 -G 1002,1003,1004,1005,1006

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set oracle and grid limits"
echo "-----------------------------------------------------------------"
cat << EOL >> /etc/security/limits.conf
# Grid user
grid soft nofile 131072
grid hard nofile 131072
grid soft nproc 131072
grid hard nproc 131072
grid soft core unlimited
grid hard core unlimited
grid soft memlock 98728941
grid hard memlock 98728941
grid soft stack 10240
grid hard stack 32768
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
echo -e "${INFO}`date +%F' '%T`: Create GI_HOME and DB_HOME directories"
echo "-----------------------------------------------------------------"
mkdir -p ${GRID_BASE}
mkdir -p ${DB_BASE}
mkdir -p ${GRID_HOME}
mkdir -p ${DB_HOME}
chown -R grid:oinstall /u01
chown -R grid:oinstall ${GRID_BASE}
chown -R grid:oinstall ${GRID_HOME}
chown -R oracle:oinstall ${DB_BASE}
chown -R oracle:oinstall ${DB_HOME}
chmod -R ug+rw /u01

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Set user env"
echo "-----------------------------------------------------------------"
if [ `hostname` == ${NODE1_HOSTNAME} ]
then
  cat >> /home/grid/.bash_profile << EOF
export ORACLE_HOME=${GRID_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
EOF
  if [ "${ORESTART}" == "false" ]
  then
    cat >> /home/grid/.bash_profile << EOF
export ORACLE_SID=+ASM1
EOF
  else
    cat >> /home/grid/.bash_profile << EOF
export ORACLE_SID=+ASM
EOF
  fi

  cat >> /home/oracle/.bash_profile << EOF
export ORACLE_HOME=${DB_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
EOF
  if [ "${DB_TYPE}" == "SI" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}
EOF
  elif [ "${DB_TYPE}" == "RACONE" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}_1
EOF
  elif [ "${DB_TYPE}" == "RAC" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}1
EOF
  fi
fi

if [ `hostname` == ${NODE2_HOSTNAME} ]
then
  cat >> /home/grid/.bash_profile << EOF
export ORACLE_HOME=${GRID_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
EOF
  if [ "${ORESTART}" == "false" ]
  then
    cat >> /home/grid/.bash_profile << EOF
export ORACLE_SID=+ASM2
EOF
  else
    cat >> /home/grid/.bash_profile << EOF
export ORACLE_SID=+ASM
EOF
  fi

  cat >> /home/oracle/.bash_profile << EOF
export ORACLE_HOME=${DB_HOME}
export PATH=\$ORACLE_HOME/bin:$PATH
EOF
  if [ "${DB_TYPE}" == "SI" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}
EOF
  elif [ "${DB_TYPE}" == "RACONE" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}_2
EOF
  elif [ "${DB_TYPE}" == "RAC" ]
  then
    cat >> /home/oracle/.bash_profile << EOF
export ORACLE_SID=${DB_NAME}2
EOF
  fi
fi

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


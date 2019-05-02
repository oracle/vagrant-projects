#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/06_do_RDBMS_software_installation.sh,v 2.0.1.1 2018/12/10 11:15:28 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      06_do_RDBMS_software_installation
#
#    DESCRIPTION
#      RDBMS software install
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
. /vagrant_config/setup.env

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Unzip RDBMS software"
echo "-----------------------------------------------------------------"
cd ${DB_HOME}
unzip -oq /vagrant/ORCL_software/${DB_SOFTWARE}

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Installing RDBMS software"
echo "-----------------------------------------------------------------"

${DB_HOME}/runInstaller -ignorePrereq -waitforcompletion -silent \
        -responseFile ${DB_HOME}/install/response/db_install.rsp \
        oracle.install.option=INSTALL_DB_SWONLY \
        UNIX_GROUP_NAME=oinstall \
        INVENTORY_LOCATION=${ORA_INVENTORY} \
        SELECTED_LANGUAGES=${ORA_LANGUAGES} \
        ORACLE_HOME=${DB_HOME} \
        ORACLE_BASE=${DB_BASE} \
        oracle.install.db.InstallEdition=EE \
        oracle.install.db.OSDBA_GROUP=dba \
        oracle.install.db.OSBACKUPDBA_GROUP=backupdba \
        oracle.install.db.OSDGDBA_GROUP=dgdba \
        oracle.install.db.OSKMDBA_GROUP=kmdba \
        oracle.install.db.OSRACDBA_GROUP=racdba \
        SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
        DECLINE_SECURITY_UPDATES=true

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

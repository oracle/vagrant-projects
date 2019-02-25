#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/06_do_RDBMS_software_installation.sh,v 2.0.1.1 2018/11/18 23:12:36 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      06_do_RDBMS_software_installation
#
#    DESCRIPTION
#      RDBMS software install
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

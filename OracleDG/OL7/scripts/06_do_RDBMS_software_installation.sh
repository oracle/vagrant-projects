#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
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
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     11/06/18 - Creation
# 
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env

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

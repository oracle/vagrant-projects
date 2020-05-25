#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      13_Setup_FPP.sh
#
#    DESCRIPTION
#      FPP Setup
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

${GI_HOME}/bin/asmcmd setattr -G DATA compatible.asm ${GI_VERSION}

${GI_HOME}/bin/srvctl add gns -vip ${GNS_IP}
${GI_HOME}/bin/srvctl start gns

${GI_HOME}/bin/srvctl add havip -id rhphavip -address ${HA_VIP}

${GI_HOME}/bin/srvctl stop rhpserver
${GI_HOME}/bin/srvctl remove rhpserver

${GI_HOME}/bin/srvctl add rhpserver -storage /rhp_storage -diskgroup DATA
${GI_HOME}/bin/srvctl start rhpserver
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

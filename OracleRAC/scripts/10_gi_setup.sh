#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/10_gi_setup.sh,v 2.0.1.2 2019/04/29 08:37:39 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      10_gi_setup.sh
#
#    DESCRIPTION
#      GI Setup
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

sh ${ORA_INVENTORY}/orainstRoot.sh
if [ "${ORESTART}" == "false" ]
then
  sh ${GI_HOME}/root.sh
  ssh root@${NODE2_HOSTNAME} sh ${ORA_INVENTORY}/orainstRoot.sh
  ssh root@${NODE2_HOSTNAME} sh ${GI_HOME}/root.sh
else
  ${GI_HOME}/perl/bin/perl -I ${GI_HOME}/perl/lib -I ${GI_HOME}/crs/install ${GI_HOME}/crs/install/roothas.pl
fi

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

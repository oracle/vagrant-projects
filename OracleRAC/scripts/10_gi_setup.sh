#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/10_gi_setup.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      10_gi_setup.sh
#
#    DESCRIPTION
#      GI Setup
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

sh ${ORA_INVENTORY}/orainstRoot.sh
if [ "${ORESTART}" == "false" ]
then
  sh ${GRID_HOME}/root.sh
  ssh root@${NODE2_HOSTNAME} sh ${ORA_INVENTORY}/orainstRoot.sh
  ssh root@${NODE2_HOSTNAME} sh ${GRID_HOME}/root.sh
else
  ${GRID_HOME}/perl/bin/perl -I ${GRID_HOME}/perl/lib -I ${GRID_HOME}/crs/install ${GRID_HOME}/crs/install/roothas.pl
fi

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_fpp-2.0.1/scripts/10_gi_setup.sh,v 2.0.1.2 2020/02/17 12:19:54 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
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
#    rcitton     10/01/19 - Creation
#
. /vagrant_config/setup.env

sh ${ORA_INVENTORY}/orainstRoot.sh
sh ${GI_HOME}/root.sh

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

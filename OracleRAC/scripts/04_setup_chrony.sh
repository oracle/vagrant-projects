#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/04_setup_chrony.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      04_setup_chrony.sh
#
#    DESCRIPTION
#      Setup chronyd service
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
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup chronyd service"
echo "-----------------------------------------------------------------"
systemctl enable chronyd
systemctl restart chronyd
chronyc -a makestep

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

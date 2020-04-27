#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_fpp-2.0.1/scripts/04_setup_chrony.sh,v 2.0.1.2 2020/02/17 12:19:54 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      04_setup_chrony.sh
#
#    DESCRIPTION
#      Setup chronyd service
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     10/01/19 - Creation
##
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup chronyd service"
echo "-----------------------------------------------------------------"
systemctl enable chronyd
systemctl restart chronyd
chronyc -a makestep

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

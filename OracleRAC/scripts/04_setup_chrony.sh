#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/04_setup_chrony.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
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

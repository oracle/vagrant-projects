#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_rac-2.0.1/scripts/00_purgelog.sh,v 2.0.1.1 2018/12/10 11:18:35 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      00_purgelog.sh
#
#    DESCRIPTION
#      Setup purgelog utility
#      See MOS Doc ID 2081655.1
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
echo -e "${INFO}`date +%F' '%T`: Setting-up purgelog utility"
echo "-----------------------------------------------------------------"

cat >> /etc/cron.d/purgeLogs <<EOF
00 02 * * * /vagrant_utilities/purgeLogs -orcl 5 -tfa 5 -aud -lsnr
EOF

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

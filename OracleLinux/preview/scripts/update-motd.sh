#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: October, 2018
# Author: simon.coter@oracle.com
# Description: Updates Oracle Linux to the latest version
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Updating /etc/motd for Oracle Linux 7 Update 6 Preview'
cp /etc/motd /etc/motd.original

cat > /etc/motd <<EOF

Welcome to Oracle Linux Server release 7.6 Preview

The Oracle Linux End-User License Agreement can be viewed here:

    * /usr/share/eula/eula.en_US

For additional packages, updates, documentation and community help, see:

    * http://yum.oracle.com/

EOF

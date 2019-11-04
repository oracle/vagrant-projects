#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: June, 2018
# Author: philippe.vanhaesendonck@oracle.com
# Description: Installs Docker Engine and runs a registry container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo "Run docker registry"
docker run \
        --detach \
        --restart unless-stopped \
        --name registry \
        --publish 5000:5000 \
        registry:2

echo "Your Registry VM is ready to use!"

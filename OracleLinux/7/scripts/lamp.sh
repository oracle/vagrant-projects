#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2020 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: gerald.venzl@oracle.com
# Description: Updates Oracle Linux to the latest version
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo 'INSTALLER: Enabling MySQL and Software Collection Yum repositories'

# install yum-config-manager to get yum repos managed
yum install yum-utils -y

# enable software-collection yum repository
yum install -y oracle-softwarecollection-release-el7.x86_64

# enable MySQL yum repository
yum install mysql-release-el7.x86_64 -y

echo 'INSTALLER: Installing Apache Web Server from Oracle Linux Software Collections'

# get Apache2 from software-collections installed and running
yum install httpd24 -y
systemctl enable httpd24-httpd
systemctl start httpd24-httpd

echo 'INSTALLER: Installing MySQL Community Release 8'

# get MySQL Community 8
yum install mysql-community-server.x86_64 mysql-community-client.x86_64 -y
systemctl enable mysqld
systemctl start mysqld

echo 'INSTALLER: Installing PHP 7.3 from Oracle Linux Software Collections'
# get PHP 7.0
yum install rh-php73.x86_64 rh-php73-php rh-php73-php-mysqlnd.x86_64 rh-php73-php-fpm.x86_64 -y
systemctl enable rh-php73-php-fpm
systemctl start rh-php73-php-fpm

echo 'INSTALLER: Configuring Apache Server'
cat > /opt/rh/httpd24/root/var/www/html/info.php << EOF
<?php
phpinfo();
?>
EOF

systemctl restart httpd24-httpd

cat > /etc/motd << EOF

Welcome to Oracle Linux Server release 7
LAMP architecture based on Oracle Linux Software Collections:
 - Apache 2.4, MySQL Community 8 and PHP 7.3

The Oracle Linux End-User License Agreement can be viewed here:

    * /usr/share/eula/eula.en_US

For additional packages, updates, documentation and community help, see:

    * https://yum.oracle.com/

To test your environment is correctly working, just open following URL from your Host OS:
http://localhost:8080/info.php

Please use following commands to enable Software Collection environments:
- Apache 2.4: # scl enable httpd24 /bin/bash
- PHP 7.3: # scl enable rh-php73 /bin/bash
EOF

#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/08_setup_autostart.sh,v 2.0.1.1 2018/12/10 11:15:28 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      08_setup_autostart.sh
#
#    DESCRIPTION
#      Setup for autostart
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

mkdir /home/oracle/scripts
cat > /home/oracle/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/oracle/.bash_profile
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbstart \$ORACLE_HOME
EOF

cat > /home/oracle/scripts/stop_all.sh <<EOF
#!/bin/bash
. /home/oracle/.bash_profile
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbshut \$ORACLE_HOME
EOF

chown -R oracle.oinstall /home/oracle/scripts
chmod u+x /home/oracle/scripts/*.sh

cat > /lib/systemd/system/dbora.service <<EOF
[Unit]
Description=The Oracle Database Service
After=syslog.target network.target

[Service]
# systemd ignores PAM limits, so set any necessary limits in the service.
# Not really a bug, but a feature.
# https://bugzilla.redhat.com/show_bug.cgi?id=754285
LimitMEMLOCK=infinity
LimitNOFILE=65535

#Type=simple
# idle: similar to simple, the actual execution of the service binary is delayed
#       until all jobs are finished, which avoids mixing the status output with shell output of services.
RemainAfterExit=yes
User=oracle
Group=oinstall
Restart=no
ExecStart=/home/oracle/scripts/start_all.sh
ExecStop=/home/oracle/scripts/stop_all.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start dbora.service
systemctl enable dbora.service 2>&1 > /dev/null

cat > /etc/oratab <<EOF
${DB_NAME}:${DB_HOME}:Y
EOF

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


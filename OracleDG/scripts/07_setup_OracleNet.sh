#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/07_setup_OracleNet.sh,v 2.0.1.1 2018/11/18 23:12:36 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      07_setup_OracleNet.sh
#
#    DESCRIPTION
#      Setup for oracle tnsnames and listener
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

cat > ${DB_HOME}/network/admin/tnsnames.ora <<EOF
LISTENER = (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE1_HOSTNAME})(PORT = 1521))

${DB_NAME} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE1_HOSTNAME})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ${DB_NAME})
    )
  )

${DB_NAME}_STDBY =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ${DB_NAME})
    )
  )
EOF

if [ `hostname` == ${NODE1_HOSTNAME} ]
then
cat > ${DB_HOME}/network/admin/listener.ora <<EOF
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE1_HOSTNAME})(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${DB_NAME}_DGMGRL)
      (DB_HOME = ${DB_HOME})
      (SID_NAME = ${DB_NAME})
    )
  )

ADR_BASE_LISTENER = ${DB_BASE}
INBOUND_CONNECT_TIMEOUT_LISTENER=400
EOF
fi

if [ `hostname` == ${NODE2_HOSTNAME} ]
then
cat > ${DB_HOME}/network/admin/listener.ora <<EOF
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${DB_NAME}_DGMGRL)
      (DB_HOME = ${DB_HOME})
      (SID_NAME = ${DB_NAME})
    )
  )

ADR_BASE_LISTENER = ${DB_BASE}
INBOUND_CONNECT_TIMEOUT_LISTENER=400
EOF
fi


cat > ${DB_HOME}/network/admin/sqlnet.ora <<EOF
SQLNET.INBOUND_CONNECT_TIMEOUT=400
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Oracle listener start"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/lsnrctl start

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------


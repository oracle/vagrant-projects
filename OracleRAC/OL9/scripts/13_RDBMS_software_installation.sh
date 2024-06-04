. /vagrant/config/setup.env
/u01/app/oracle/product/21.3.0.0/dbhome_1/runInstaller -ignorePrereq -waitforcompletion -silent \
        -responseFile /u01/app/oracle/product/21.3.0.0/dbhome_1/install/response/db_install.rsp \
        oracle.install.option=INSTALL_DB_SWONLY \
        ORACLE_HOSTNAME= \
        UNIX_GROUP_NAME=oinstall \
        INVENTORY_LOCATION=/u01/app/oraInventory \
        SELECTED_LANGUAGES=en,en_GB \
        ORACLE_HOME=/u01/app/oracle/product/21.3.0.0/dbhome_1 \
        ORACLE_BASE=/u01/app/oracle \
        oracle.install.db.InstallEdition=EE \
        oracle.install.db.OSDBA_GROUP=dba \
        oracle.install.db.OSBACKUPDBA_GROUP=dba \
        oracle.install.db.OSDGDBA_GROUP=dba \
        oracle.install.db.OSKMDBA_GROUP=dba \
        oracle.install.db.OSRACDBA_GROUP=dba \
        oracle.install.db.CLUSTER_NODES=node1,node2 \
        oracle.install.db.isRACOneInstall=false \
        oracle.install.db.rac.serverpoolCardinality=0 \
        oracle.install.db.config.starterdb.type=GENERAL_PURPOSE \
        oracle.install.db.ConfigureAsContainerDB=true \
        SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
        DECLINE_SECURITY_UPDATES=true

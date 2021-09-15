. /vagrant/config/setup.env
/u01/app/21.3.0.0/grid/gridSetup.sh -silent -executeConfigTools \
    -responseFile /u01/app/21.3.0.0/grid/install/response/gridsetup.rsp \
    INVENTORY_LOCATION=/u01/app/oraInventory \
    SELECTED_LANGUAGES=en,en_GB \
    oracle.install.option=CRS_CONFIG \
    ORACLE_BASE=/u01/app/grid \
    oracle.install.asm.OSDBA=asmdba \
    oracle.install.asm.OSOPER=asmoper \
    oracle.install.asm.OSASM=asmadmin \
    oracle.install.crs.config.scanType=LOCAL_SCAN \
    oracle.install.crs.config.gpnp.scanName=vgt-213-rac-scan \
    oracle.install.crs.config.gpnp.scanPort=1521 \
    oracle.install.crs.config.clusterName=vgt-213-rac-c \
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \
    oracle.install.crs.config.configureAsExtendedCluster=false \
    oracle_install_crs_ConfigureMgmtDB=false \
    oracle.install.crs.config.gpnp.configureGNS=false \
    oracle.install.crs.config.autoConfigureClusterNodeVIP=false \
    oracle.install.asm.configureGIMRDataDG=false \
    oracle.install.crs.config.useIPMI=false \
    oracle.install.asm.storageOption=ASM \
    oracle.install.asmOnNAS.configureGIMRDataDG=false \
    oracle.install.asm.SYSASMPassword=welcome1 \
    oracle.install.asm.diskGroup.name=DATA \
    oracle.install.asm.diskGroup.redundancy=EXTERNAL \
    oracle.install.asm.diskGroup.AUSize=4 \
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=/dev/ORCL_DISK1_p1,,/dev/ORCL_DISK2_p1,,/dev/ORCL_DISK3_p1,,/dev/ORCL_DISK4_p1, \
    oracle.install.asm.diskGroup.disks=/dev/ORCL_DISK1_p1,/dev/ORCL_DISK2_p1,/dev/ORCL_DISK3_p1,/dev/ORCL_DISK4_p1 \
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleafd/disks/ORCL_*,AFD:* \
    oracle.install.asm.configureAFD=true \
    oracle.install.asm.gimrDG.AUSize=1 \
    oracle.install.asm.monitorPassword=welcome1 \
    oracle.install.crs.configureRHPS=false \
    oracle.install.crs.config.ignoreDownNodes=false \
    oracle.install.config.managementOption=NONE \
    oracle.install.config.omsPort=0 \
    oracle.install.crs.rootconfig.executeRootScript=false

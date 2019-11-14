#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright © 1982-2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    NAME
#      apex.sh
#
#    DESCRIPTION
#      Execute Oracle Application Express installation and configuration
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Simon Coter
#
#    MODIFIED   (MM/DD/YY)
#    scoter     03/19/19 - Creation
#

. /home/oracle/.bashrc 

export ORACLE_PWD=`cat /vagrant/apex-pwd`
ORACLE_PDB="`ls -dl $ORACLE_BASE/oradata/$ORACLE_SID/*/ | grep -v pdbseed | awk '{print $9}' | cut -d/ -f6`"
echo "export ORACLE_PDB=$ORACLE_PDB" >> /home/oracle/.bashrc

# Install new apex release
cd $ORACLE_HOME
APEX_INSTALL=`ls /vagrant/apex_1*.*.zip |tail -1`
unzip $APEX_INSTALL
chown -R oracle:oinstall $ORACLE_HOME/apex
cd -

echo 'INSTALLER: Updated APEX extracted to the ORACLE_HOME'

# Prepare APEX tablespaces
su -l oracle -c "sqlplus / as sysdba <<EOF
	ALTER DATABASE DATAFILE '$ORACLE_BASE/oradata/$ORACLE_SID/system01.dbf' resize 1024m;
	ALTER DATABASE DATAFILE '$ORACLE_BASE/oradata/$ORACLE_SID/sysaux01.dbf' resize 1024m;
	alter session set container=$ORACLE_PDB;
	CREATE TABLESPACE apex DATAFILE '$ORACLE_BASE/oradata/$ORACLE_SID/$ORACLE_PDB/apex01.dbf'
        SIZE 300M AUTOEXTEND ON NEXT 1M;
	exit;
EOF"

echo 'INSTALLER: APEX tablespaces created'

# Install APEX into the PDB Oracle Database
su -l oracle -c "cd $ORACLE_HOME/apex; sqlplus / as sysdba <<EOF
	alter session set container=$ORACLE_PDB;
	@apexins.sql APEX APEX TEMP /i/
	exit;
EOF"

echo 'INSTALLER: Oracle APEX Installation completed'

# unlock APEX_PUBLIC_USER
su -l oracle -c "cd $ORACLE_HOME/apex; sqlplus / as sysdba <<EOF
	alter session set container=$ORACLE_PDB;
	alter user APEX_PUBLIC_USER identified by \"${ORACLE_PWD}\" account unlock;
	exit;
EOF"

# Create the APEX Instance Administration user and set the password
su -l oracle -c "sqlplus / as sysdba <<EOF
	alter session set container=$ORACLE_PDB;
	begin
	    apex_util.set_security_group_id( 10 );
	    apex_util.create_user(
	        p_user_name => 'ADMIN',
	        p_email_address => 'your@emailaddress.com',
	        p_web_password => '${ORACLE_PWD}',
	        p_developer_privs => 'ADMIN' );
	    apex_util.set_security_group_id( null );
	    commit;
	end;
	/
	exit;
EOF"

# config APEX REST and set the passwords of APEX_REST_PUBLIC_USER and APEX_LISTENER
su -l oracle -c "cd $ORACLE_HOME/apex; sqlplus / as sysdba <<EOF
        alter session set container=$ORACLE_PDB;
        @apex_rest_config_core.sql $ORACLE_HOME/apex/ ${ORACLE_PWD} ${ORACLE_PWD}
        exit;
EOF"

# Create a network ACE for APEX (this is used when consuming Web services or sending outbound mail)
cat > /tmp/apex-ace.sql << EOF
        alter session set container=$ORACLE_PDB;
        declare
            l_acl_path varchar2(4000);
            l_apex_schema varchar2(100);
        begin
            for c1 in (select schema
                         from sys.dba_registry
                        where comp_id = 'APEX') loop
                l_apex_schema := c1.schema;
            end loop;
            sys.dbms_network_acl_admin.append_host_ace(
                host => '*',
                ace => xs\$ace_type(privilege_list => xs\$name_list('connect'),
                principal_name => l_apex_schema,
                principal_type => xs_acl.ptype_db));
            commit;
        end;
	/
	exit;
EOF
su -l oracle -c "sqlplus / as sysdba @/tmp/apex-ace.sql"
rm -f /tmp/apex-ace.sql

echo 'INSTALLER: Oracle APEX Configuration completed'

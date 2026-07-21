#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 05_setup_users.sh
#   Create the oracle user, groups, HugePages, shell limits and the DB home
#   directories. The oracle user is created with a locked password; setup.sh
#   sets it afterwards via chpasswd.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var DB_BASE
require_var DB_HOME
require_var INSTANCE_NAME
require_var HUGEPAGES

log_section "Preparing oracle user and groups"

# Drop any pre-existing oracle/groups from the base box. Failures are tolerated.
userdel  -fr  oracle     2>/dev/null || true
for g in oinstall dba backupdba dgdba kmdba racdba dbaoper; do
  groupdel "${g}" 2>/dev/null || true
done

groupadd -g 1001 oinstall
groupadd -g 1002 dbaoper
groupadd -g 1003 dba
groupadd -g 1007 backupdba
groupadd -g 1008 dgdba
groupadd -g 1009 kmdba
groupadd -g 1010 racdba

# Create oracle with a LOCKED password (!). setup.sh assigns the real password
# afterwards via chpasswd — no cleartext on the command line.
useradd oracle \
  -d /home/oracle -m \
  -s /bin/bash \
  -g oinstall \
  -G dbaoper,dba,backupdba,dgdba,kmdba,racdba \
  -p '!'

log_section "Configuring HugePages (vm.nr_hugepages=${HUGEPAGES})"
hugepages_file='/etc/sysctl.d/98-oracle-hugepages.conf'
cat > "${hugepages_file}" <<EOF
vm.nr_hugepages=${HUGEPAGES}
EOF
chmod 0644 "${hugepages_file}"
sysctl --system >/dev/null || true

log_section "Setting oracle shell limits"
limits_file='/etc/security/limits.d/99-oracle.conf'
cat > "${limits_file}" <<'EOF'
# Oracle user limits (managed by Vagrant provisioner)
oracle soft nofile   131072
oracle hard nofile   131072
oracle soft nproc    131072
oracle hard nproc    131072
oracle soft core     unlimited
oracle hard core     unlimited
oracle soft memlock  98728941
oracle hard memlock  98728941
oracle soft stack    10240
oracle hard stack    32768
EOF
chmod 0644 "${limits_file}"

log_section "Creating ORACLE_HOME / ORADATA directories"
mkdir -p "${DB_BASE}" "${DB_HOME}" /u01/app/stage /u02/oradata
chown -R oracle:oinstall /u01/app /u02/oradata
chmod -R u+rwX,g+rwX     /u01 /u02

log_section "Writing oracle user profile"
cat > /home/oracle/.bash_profile <<EOF
# .bash_profile — managed by Vagrant provisioner
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.bashrc ] && . ~/.bashrc

export ORACLE_BASE='${DB_BASE}'
export ORACLE_HOME='${DB_HOME}'
export ORACLE_SID='${INSTANCE_NAME}'
export PATH="\${ORACLE_HOME}/bin:\${PATH}"
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib:\${LD_LIBRARY_PATH:-}"
EOF
chown oracle:oinstall /home/oracle/.bash_profile
chmod 0644 /home/oracle/.bash_profile

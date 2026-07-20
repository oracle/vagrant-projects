#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 05_setup_users.sh
#   Create grid + oracle users, groups, shell limits, ORACLE_HOME directories.
#   Both accounts are created with a locked password (-p '!'). The orchestrator
#   assigns the real passwords afterwards via chpasswd (no cleartext on argv).
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
for v in GRID_BASE DB_BASE GI_HOME DB_HOME DB_NAME \
         NODE1_HOSTNAME NODE2_HOSTNAME; do
  require_var "${v}"
done

log_section "Preparing oracle + grid users and groups"

# Drop any pre-existing accounts/groups from the base box. Failures tolerated.
for u in oracle grid; do userdel -fr "${u}" 2>/dev/null || true; done
for g in oinstall dba backupdba dgdba kmdba racdba dbaoper asmadmin asmoper asmdba; do
  groupdel "${g}" 2>/dev/null || true
done

groupadd -g 1001 oinstall
groupadd -g 1002 dbaoper
groupadd -g 1003 dba
groupadd -g 1004 asmadmin
groupadd -g 1005 asmoper
groupadd -g 1006 asmdba
groupadd -g 1007 backupdba
groupadd -g 1008 dgdba
groupadd -g 1009 kmdba
groupadd -g 1010 racdba

# Oracle owner for the RDBMS home — NOT in the asm* groups.
useradd oracle \
  -d /home/oracle -m \
  -s /bin/bash \
  -g oinstall \
  -G dbaoper,dba,asmadmin,asmdba,backupdba,dgdba,kmdba,racdba \
  -p '!'

# Grid owner for the Grid Infrastructure home — NOT in the db* groups.
useradd grid \
  -d /home/grid -m \
  -s /bin/bash \
  -g oinstall \
  -G dbaoper,asmadmin,asmoper,asmdba \
  -p '!'

log_section "Setting grid + oracle shell limits"
limits_file='/etc/security/limits.d/99-oracle-seha.conf'
cat > "${limits_file}" <<'EOF'
# Oracle SEHA user limits (managed by Vagrant provisioner)
grid   soft nofile   131072
grid   hard nofile   131072
grid   soft nproc    131072
grid   hard nproc    131072
grid   soft core     unlimited
grid   hard core     unlimited
grid   soft memlock  98728941
grid   hard memlock  98728941
grid   soft stack    10240
grid   hard stack    32768

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

log_section "Creating GI_HOME + DB_HOME directories"
mkdir -p "${GRID_BASE}" "${DB_BASE}" "${GI_HOME}" "${DB_HOME}"
chown -R grid:oinstall   /u01 "${GRID_BASE}" "${GI_HOME}"
chown -R oracle:oinstall "${DB_BASE}" "${DB_HOME}"
chmod -R u+rwX,g+rwX     /u01

log_section "Writing grid and oracle user profiles"
host="$(hostname -s)"

# ASM is per-node in the Grid Infrastructure cluster. The database itself is a
# single-instance SEHA database and keeps the same ORACLE_SID on either node.
case "${host}" in
  "${NODE1_HOSTNAME}") sid_suffix_grid='1' ;;
  "${NODE2_HOSTNAME}") sid_suffix_grid='2' ;;
  *)
    log_error "hostname '${host}' is neither ${NODE1_HOSTNAME} nor ${NODE2_HOSTNAME}"
    exit 1
    ;;
esac

cat > /home/grid/.bash_profile <<EOF
# .bash_profile — managed by Vagrant provisioner
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.bashrc ] && . ~/.bashrc
export ORACLE_BASE='${GRID_BASE}'
export ORACLE_HOME='${GI_HOME}'
export ORACLE_SID='+ASM${sid_suffix_grid}'
export PATH="\${ORACLE_HOME}/bin:\${PATH}"
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib:\${LD_LIBRARY_PATH:-}"
EOF
chown grid:oinstall /home/grid/.bash_profile
chmod 0644          /home/grid/.bash_profile

cat > /home/oracle/.bash_profile <<EOF
# .bash_profile — managed by Vagrant provisioner
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.bashrc ] && . ~/.bashrc
export ORACLE_BASE='${DB_BASE}'
export ORACLE_HOME='${DB_HOME}'
export ORACLE_SID='${DB_NAME}'
export PATH="\${ORACLE_HOME}/bin:\${PATH}"
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib:\${LD_LIBRARY_PATH:-}"
EOF
chown oracle:oinstall /home/oracle/.bash_profile
chmod 0644            /home/oracle/.bash_profile

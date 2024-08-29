#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Since: August, 2024
# Author: ruggero.citton@oracle.com
# Description: 05_setup_GDD.sh
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│

. /vagrant/config/setup.env

# Function to delete and create secrets
delete_and_create_secret() {
    local secret_name=$1
    local file_path=$2

    # Check if the secret exists
    if podman secret inspect $secret_name &> /dev/null; then
        echo "INFO: Deleting existing secret $secret_name..."
        podman secret rm $secret_name
    fi

    # Create the new secret
    echo "INFO: Creating new secret $secret_name..."
    podman secret create $secret_name $file_path
}

create_secrets() {
    # Check if SHARDING_SECRET environment variable is defined
    if [ -z "$SHARDING_SECRET" ]; then
        echo "ERROR: SHARDING_SECRET environment variable is not defined."
        return 1
    fi
    mkdir -p /opt/.secrets/
    echo $SHARDING_SECRET > /opt/.secrets/pwdfile.txt
    cd /opt/.secrets
    openssl genrsa -out key.pem
    openssl rsa -in key.pem -out key.pub -pubout
    openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
    rm -rf /opt/.secrets/pwdfile.txt
    # Delete and create secrets
    delete_and_create_secret "pwdsecret" "/opt/.secrets/pwdfile.enc"
    delete_and_create_secret "keysecret" "/opt/.secrets/key.pem"
    echo "INFO: Secrets created."
    chown 54321:54321 /opt/.secrets/pwdfile.enc
    chown 54321:54321 /opt/.secrets/key.pem
    chown 54321:54321 /opt/.secrets/key.pub
    chmod 400 /opt/.secrets/pwdfile.enc
    chmod 400 /opt/.secrets/key.pem
    chmod 400 /opt/.secrets/key.pub
    # List of files
    files=(
        "/opt/.secrets/pwdfile.enc"
        "/opt/.secrets/key.pem"
        /opt/.secrets/key.pub
    )
    if grep -q '^SELINUX=enforcing' /etc/selinux/config || grep -q '^SELINUX=permissive' /etc/selinux/config; then
        for file in "${files[@]}"; do
            # Check if file context exists
            if ! grep -q "$(basename "$file")" /etc/selinux/targeted/contexts/files/file_contexts.local; then
                # If not, add file context
                semanage fcontext -a -t container_file_t "$file"
                restorecon -v "$file"
            fi
        done
        echo "SELinux is enabled. Updated file contexts."

    fi

    cd -
    return 0
}

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup Secrets"
echo "-----------------------------------------------------------------"
create_secrets

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup Podman network"
echo "-----------------------------------------------------------------"
podman network create -d macvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=eth0 shard_pub1_nw


if [ ! -z ${PODMAN_REGISTRY_URI} ] && [ ! -z ${PODMAN_REGISTRY_USER} ] && [ ! -z ${PODMAN_REGISTRY_PASSWORD} ]; then
  echo "-----------------------------------------------------------------"
  echo -e "${INFO}`date +%F' '%T`: Login to $PODMAN_REGISTRY_URI"
  echo "-----------------------------------------------------------------"
  expect <<EOF
spawn podman login -u $PODMAN_REGISTRY_USER $PODMAN_REGISTRY_URI
while (1) {
  expect {
    -re ".*Password:.*" { send "$PODMAN_REGISTRY_PASSWORD\r" }
    "Error response from daemon:*" { exit 1 }
    eof { break }
  }
}
EOF
  if [ $? != 0 ]; then
   echo -e "${ERROR} Login to '$PODMAN_REGISTRY_URI', exiting..."
   exit 1
  fi
fi


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Run GDD podman-compose"
echo "-----------------------------------------------------------------"
source /vagrant/scripts/podman-compose-prerequisites-free.sh
source /vagrant/scripts/set-file-context.sh
cd /vagrant/scripts
podman-compose up -d

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

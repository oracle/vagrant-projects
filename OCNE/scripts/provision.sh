#!/bin/bash
#
# Provision Oracle Cloud Native Environment nodes
#
# Copyright (c) 2019, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Description: Installs the Oracle Cloud Native Environment packages,
# configures all prerequisites and deploys the Kubernetes module.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Constants
readonly CERT_DIR=/etc/olcne/pki
readonly EXTERNALIP_VALIDATION_CERT_DIR=/etc/olcne/pki-externalip-validation-webhook

#######################################
# Convenience function used to limit output during provisioning
# Exit on error
# Prepend any command with "echo_do"
# Caveats:
#   - Quoted parameters need to be quoted 2 times
#     E.g.: echo_do ls "'a b'"
#   - Statements with redirects need to be evaluated twice
#     E.g.: echo_do eval "ls >x"
# Globals:
#   VERBOSE
# Arguments:
#   Command to run
# Returns:
#   None
#######################################
echo_do() {
  local tmp_file
  local ret_code

  [[ -n "${VERBOSE}" ]] && echo "    $*"
  tmp_file=$(mktemp /var/tmp/cmd_XXXXX.log)
  eval "$@" > "${tmp_file}" 2>&1
  ret_code=$?
  if [[ ${ret_code} -ne 0 ]]; then
    [[ -z "${VERBOSE}" ]] && echo "$@"
    echo "Returned a non-zero code: ${ret_code}" >&2
    echo "Last output lines:" >&2
    tail -5 "${tmp_file}" >&2
    echo "See ${tmp_file} for details" >&2
    exit ${ret_code}
  fi
  rm "${tmp_file}"
}

#######################################
# Just print a message
# Globals:
#   None
# Arguments:
#   Text to be printed
# Returns:
#   None
#######################################
msg() {
  echo "===== ${*} ====="
}

#######################################
# Parse arguments
# Exit on error.
# Globals:
#   OCNE_DEV OCNE_VERSION K8S_VERSION MASTER MASTERS WORKER WORKERS
#   OPERATOR MULTI_MASTER REGISTRY_OCNE VERBOSE EXTRA_REPO
#   NGINX_IMAGE
# Arguments:
#   Command line
# Returns:
#   None
#######################################
parse_args() {
  OCNE_CLUSTER_NAME='' OCNE_ENV_NAME='' OCNE_DEV=0 OCNE_VERSION='' REGISTRY_OCNE=''
  OPERATOR=0 MULTI_MASTER=0 MASTER=0 MASTERS='' WORKER=0 WORKERS=''
  VERBOSE=0 SUBNET='' EXTRA_REPO='' NGINX_IMAGE=''
  POD_NETWORK=calico DEPLOY_CALICO=0 CALICO_MODULE_NAME='' DEPLOY_MULTUS=0 MULTUS_MODULE_NAME=''
  DEPLOY_HELM=0 HELM_MODULE_NAME='' DEPLOY_ISTIO=0 ISTIO_MODULE_NAME=''
  DEPLOY_METALLB=0 METALLB_MODULE_NAME='' DEPLOY_GLUSTER=0 GLUSTER_MODULE_NAME=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
      "--master")
        MASTER=1
        shift
        ;;
      "--worker")
        WORKER=1
        shift
        ;;
      "--operator")
        OPERATOR=1
        shift
        ;;
      "--multi-master")
        MULTI_MASTER=1
        shift
        ;;
      "--ocne-dev")
        OCNE_DEV=1
        shift
        ;;
      "--ocne-environment-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --ocne-environment-name" >&2
          exit 1
        fi
        OCNE_ENV_NAME="$2"
        shift; shift;
        ;;
      "--ocne-cluster-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --ocne-cluster-name" >&2
          exit 1
        fi
        OCNE_CLUSTER_NAME="$2"
        shift; shift;
        ;;
      "--nginx-image")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --nginx-image" >&2
          exit 1
        fi
        NGINX_IMAGE="$2"
        shift; shift
        ;;
      "--repo")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --repo" >&2
	        exit 1
        fi
        EXTRA_REPO="$2"
        shift; shift
        ;;
      "--registry-ocne")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --registry-ocne" >&2
	        exit 1
        fi
        REGISTRY_OCNE="$2"
        shift; shift
        ;;
      "--masters")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --masters" >&2
	        exit 1
        fi
        MASTERS="$2"
        shift; shift
        ;;
      "--workers")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --workers" >&2
	        exit 1
        fi
        WORKERS="$2"
        shift; shift
        ;;
      "--pod-network")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --pod-network" >&2
	        exit 1
        fi
        POD_NETWORK="$2"
        shift; shift
        ;;

      "--with-calico")
        DEPLOY_CALICO=1
        shift
        ;;
      "--calico-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --calico-module-name" >&2
	        exit 1
        fi
        CALICO_MODULE_NAME="$2"
        shift; shift
        ;;
      "--with-multus")
        DEPLOY_MULTUS=1
        shift
        ;;
      "--multus-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --multus-module-name" >&2
	        exit 1
        fi
        MULTUS_MODULE_NAME="$2"
        shift; shift
        ;;
      "--with-helm")
        DEPLOY_HELM=1
        shift
        ;;
      "--helm-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --helm-module-name" >&2
	        exit 1
        fi
        HELM_MODULE_NAME="$2"
        shift; shift
        ;;
      "--with-istio")
        DEPLOY_ISTIO=1
        shift
        ;;
      "--istio-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --istio-module-name" >&2
	        exit 1
        fi
        ISTIO_MODULE_NAME="$2"
        shift; shift
        ;;
      "--with-metallb")
        DEPLOY_METALLB=1
        shift
        ;;
      "--metallb-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --metallb-module-name" >&2
	        exit 1
        fi
        METALLB_MODULE_NAME="$2"
        shift; shift
        ;;
      "--with-gluster")
        DEPLOY_GLUSTER=1
        shift
        ;;
      "--gluster-module-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --gluster-module-name" >&2
	        exit 1
        fi
        GLUSTER_MODULE_NAME="$2"
        shift; shift
        ;;
      "--subnet")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --subnet" >&2
          exit 1
        fi
        SUBNET="$2"
        shift; shift;
        ;;
      "--verbose")
        VERBOSE=1
        shift
        ;;
      *)
        echo "Invalid parameter: $1" >&2
        exit 1
        ;;
    esac
  done

  readonly OCNE_CLUSTER_NAME OCNE_ENV_NAME OCNE_DEV REGISTRY_OCNE
  readonly OPERATOR MULTI_MASTER MASTER MASTERS WORKER WORKERS
  readonly VERBOSE EXTRA_REPO NGINX_IMAGE
  readonly POD_NETWORK
  readonly DEPLOY_CALICO CALICO_MODULE_NAME
  readonly DEPLOY_MULTUS MULTUS_MODULE_NAME
  readonly DEPLOY_HELM HELM_MODULE_NAME
  readonly DEPLOY_ISTIO ISTIO_MODULE_NAME
  readonly DEPLOY_METALLB METALLB_MODULE_NAME
  readonly DEPLOY_GLUSTER GLUSTER_MODULE_NAME
}

#######################################
# Configure repos for the installation
# Globals:
#   EXTRA_REPO
#   OCNE_DEV
# Arguments:
#   None
# Returns:
#   None
#######################################
setup_repos() {
  msg "Configure repos for Oracle Cloud Native Environment"

  # Add OCNE release package
  echo_do sudo dnf install -y oracle-olcne-release-el8
  echo_do sudo dnf config-manager --enable ol8_olcne16 ol8_addons ol8_baseos_latest ol8_appstream ol8_kvm_appstream ol8_UEKR7
  echo_do sudo dnf config-manager --disable ol8_olcne15 ol8_olcne14 ol8_olcne13 ol8_olcne12

  # Optional extra repo
  if [[ -n ${EXTRA_REPO} ]]; then echo_do sudo dnf config-manager --add-repo "${EXTRA_REPO}"; fi

  # Enable OCNE developer channel
  if [[ ${OCNE_DEV} == 1 ]]; then echo_do sudo dnf config-manager --enable ol8_developer_olcne; fi
}

#######################################
# Clean up private network interface
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
clean_networking() {
  msg "Removing extra NetworkManager connection"
  nmcli -f GENERAL.STATE con show "Wired connection 1" && sudo nmcli con del "Wired connection 1"
}

#######################################
# Fulfil requirements
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
requirements() {
  msg "Fulfil requirements"
  # Disable Swap
  echo_do sudo swapoff -a
  echo_do sudo sed -i "'/ swap /d'" /etc/fstab

  # Enable transparent masquerading VxLAN
  echo_do sudo modprobe br_netfilter
  echo_do "echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf"

  # Bridge Tunable Parameters
  echo_do "cat <<-EOF | sudo tee /etc/sysctl.d/k8s.conf
	net.bridge.bridge-nf-call-ip6tables = 1
	net.bridge.bridge-nf-call-iptables = 1
	net.ipv4.ip_forward = 1
	EOF"
  echo_do sudo /sbin/sysctl -p /etc/sysctl.d/k8s.conf
  
  # Enable & start firewalld; add eth1 (nat) to the public zone
  echo_do sudo systemctl enable --now firewalld.service
  echo_do sudo firewall-cmd --zone=public --add-interface=eth1 --permanent
}

#######################################
# Install packages on the node
# Note: As of OCNE 1.0.1 kubernetes packages are deployed automatically.
# We are still installing them to be able to customize the configuration for
# the vagrant environment.
# Globals:
#   OPERATOR OCNE_VERSION MASTER WORKER K8S_VERSION MULTI_MASTER
#   REGISTRY_OCNE NGINX_IMAGE
# Arguments:
#   None
# Returns:
#   None
#######################################
install_packages() {

  ### `nft_masq` is not part of kernel-uek-core since OL8U7. To enable masquerading, we must install kernel-uek-modules
  ### https://docs.oracle.com/en/operating-systems/uek/7/relnotes7.0/uek7.0-NewFeaturesandChanges.html
  msg "Installing kernel-uek-modules"
  echo_do sudo dnf install -y kernel-uek-modules-$(uname -r)
  msg "Installing the OpenSSL toolkit"
  echo_do sudo dnf install -y openssl
  ###
    
  if [[ ${OPERATOR} == 1 ]]; then
    msg "Installing the Oracle Cloud Native Environment Platform API Server and Platform CLI tool to the operator node."
    echo_do sudo dnf install -y olcnectl"${OCNE_VERSION}" olcne-api-server"${OCNE_VERSION}" olcne-utils"${OCNE_VERSION}"
    echo_do sudo systemctl enable olcne-api-server.service
    echo_do sudo firewall-cmd --add-port=8091/tcp --permanent
    echo_do sudo firewall-cmd --add-masquerade --permanent
  fi
  if [[ ${MASTER} == 1 || ${WORKER} == 1 ]]; then
    msg "Installing the Oracle Cloud Native Environment Platform Agent"
    echo_do sudo dnf install -y olcne-agent"${OCNE_VERSION}" olcne-utils"${OCNE_VERSION}"
    echo_do sudo systemctl enable olcne-agent.service
    if [[ -n ${HTTP_PROXY} ]]; then
      # CRI-O proxies
      echo_do "sudo mkdir -p /etc/systemd/system/crio.service.d"
      echo_do "cat <<-EOF | sudo tee /etc/systemd/system/crio.service.d/crio-proxy.conf
	[Service]
	Environment=\"HTTP_PROXY=${HTTP_PROXY}\"
	Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"
	Environment=\"NO_PROXY=${NO_PROXY}\"
	EOF"
    fi
    echo_do sudo firewall-cmd --add-masquerade --permanent
    echo_do sudo firewall-cmd --zone=trusted --add-interface=cni0 --permanent
    echo_do sudo firewall-cmd --add-port=8090/tcp --permanent
    echo_do sudo firewall-cmd --add-port=10250/tcp --permanent
    echo_do sudo firewall-cmd --add-port=10255/tcp --permanent
    echo_do sudo firewall-cmd --add-port=8472/udp --permanent
    echo_do sudo firewall-cmd --add-port=30000-32767/tcp --permanent
  fi

  if [[ ${MASTER} == 1 ]]; then
    echo_do sudo dnf install -y bash-completion
    echo_do sudo firewall-cmd --add-port=6443/tcp --permanent
    echo_do sudo firewall-cmd --add-port=8001/tcp --permanent
    # OCNE 1.0.1 requires these ports for single master as well
    echo_do sudo firewall-cmd --add-port=10251/tcp --permanent
    echo_do sudo firewall-cmd --add-port=10252/tcp --permanent
    echo_do sudo firewall-cmd --add-port=2379-2380/tcp --permanent
    # Software load balancer firewall rules
    if [[ ${MULTI_MASTER} == 1 ]]; then    
      echo_do sudo firewall-cmd --add-port=6444/tcp --permanent
      echo_do sudo firewall-cmd --add-protocol=vrrp --permanent
    fi
  fi

  if [[ ${DEPLOY_METALLB} == 1 ]]; then
    if [[ ${MASTER} == 1 || ${WORKER} == 1 ]]; then
      echo_do sudo firewall-cmd --add-port=7946/tcp --permanent
      echo_do sudo firewall-cmd --add-port=7946/udp --permanent
    fi
  fi
  
  if [[ ${DEPLOY_GLUSTER} == 1 ]]; then
    if [[ ${WORKER} == 1 ]]; then
      msg "Installing the GlusterFS Server on Worker node"
      echo_do sudo dnf install -y oracle-gluster-release-el8
      echo_do sudo dnf config-manager --enable ol8_gluster_appstream
      echo_do sudo dnf module enable -y glusterfs
      echo_do sudo dnf install -y @glusterfs/server
      # Enable TLS / Management Encryption
      # https://docs.oracle.com/en/operating-systems/oracle-linux/gluster-storage/gluster-install-upgrade.html#gluster-tls
      msg "Enable GlusterFS Transport Layer Security (TLS) for Management Encryption"
      echo_do sudo openssl genrsa -out /etc/ssl/glusterfs.key 2048
      echo_do sudo openssl req -new -x509 -days 365 -key /etc/ssl/glusterfs.key -out /etc/ssl/glusterfs.pem -subj '/CN=`hostname -f`'
      echo_do eval "cat /etc/ssl/glusterfs.pem >> /vagrant/glusterfs.ca"
      echo_do sudo touch /var/lib/glusterd/secure-access
      echo_do sudo systemctl enable --now glusterd.service
      echo_do sudo firewall-cmd --add-service=glusterfs --permanent
    fi

    if [[ ${OPERATOR} == 1 ]]; then
      if [[ -f "/vagrant/glusterfs.ca" ]]; then
        msg "Distributing GlusterFS Certificate Authority's (CA) certificates"
        for node in ${WORKERS//,/ }; do
          echo_do ssh -i /vagrant/id_rsa -o "UserKnownHostsFile=/vagrant/known_hosts" "${node}" "sudo cp /vagrant/glusterfs.ca /etc/ssl/glusterfs.ca"
        done
        echo_do "rm -f /vagrant/glusterfs.ca"
      fi
	
      msg "Installing the Heketi Server & CLI on Operator node"
      echo_do sudo dnf install -y oracle-gluster-release-el8
      echo_do sudo dnf config-manager --enable ol8_gluster_appstream
      echo_do sudo dnf module enable -y glusterfs
      echo_do sudo dnf install -y heketi heketi-client
      if [[ ${MASTER} == 0 ]]; then
	# Standalone operator
	echo_do sudo firewall-cmd --add-port=8080/tcp --permanent
      fi
      msg "Modifying the default /etc/heketi/heketi.json onto /vagrant/heketi.json"
      echo_do sudo dnf install -y jq
      contents="$(jq '.use_auth=true|.jwt.admin.key="secret"|.glusterfs.executor="ssh"|.glusterfs.sshexec.keyfile="/etc/heketi/vagrant_key"|.glusterfs.sshexec.user="vagrant"|.glusterfs.sshexec.sudo=true|del(.glusterfs.sshexec.port)|del(.glusterfs.sshexec.fstab)|.glusterfs.loglevel="info"' /etc/heketi/heketi.json)" && echo -E "${contents}" > /vagrant/heketi.json
      echo_do sudo cp /vagrant/heketi.json /etc/heketi/heketi.json
      echo_do rm -f /vagrant/heketi.json
      # SSH Key *MUST* be in PEM format! Heketi would reject it otherwise.
      msg "Copying the Vagrant SSH Key. Must be in PEM format!"
      echo_do sudo cp /vagrant/id_rsa /etc/heketi/vagrant_key
      # Fix default permission which exposes the secret /etc/heketi/heketi.json
      echo_do sudo chmod 0600 /etc/heketi/vagrant_key /etc/heketi/heketi.json
      echo_do sudo chown -R heketi: /etc/heketi
      # Enable Heketi
      echo_do sudo systemctl enable --now heketi.service
      # Test Heketi
      msg "Waiting to Heketi service to become ready"
      echo_do curl --retry-connrefused --retry 10 --retry-delay 5 127.0.0.1:8080/hello
      # Heketi ready
      msg "Creating Gluster Topology file /etc/heketi/topology-ocne.json"
      # https://github.com/heketi/heketi/blob/master/docs/admin/topology.md
      jq -R '{clusters:[{nodes:(./","|map({node:{hostnames:{manage:[.],storage:[.]},zone:1},devices:[{name:"/dev/sdb",destroydata:false}]}))}]}' <<< "${WORKERS}" > /vagrant/topology-ocne.json
      echo_do sudo cp /vagrant/topology-ocne.json /etc/heketi/topology-ocne.json
      echo_do sudo chown heketi: /etc/heketi/topology-ocne.json
      msg "Loading Gluster Cluster Topology with Heketi"
      # export HEKETI_CLI_USER=admin; export HEKETI_CLI_KEY=secret
      echo_do heketi-cli --user=admin --secret=secret topology load --json=/etc/heketi/topology-ocne.json
      echo_do rm -f /vagrant/topology-ocne.json
    fi
  fi

  if [[ ${POD_NETWORK} == "calico" || ${DEPLOY_CALICO} == 1 ]]; then
    msg "Disable firewalld.service as required by Calico networking"
    echo_do sudo systemctl disable --now firewalld.service
  else
    # Reload firewalld
    echo_do sudo firewall-cmd --reload
  fi
}

#######################################
# Configure passwordless ssh between nodes
# Globals:
#   OPERATOR
# Arguments:
#   None
# Returns:
#   None
#######################################
passwordless_ssh() {
  msg "Allow passwordless ssh between VMs"
  # Generate common key
  if [[ ! -f /vagrant/id_rsa && ! -f /vagrant/id_rsa ]]; then
    msg "Generating shared SSH keypair in PEM format"
    echo_do ssh-keygen -m PEM -t rsa -f /vagrant/id_rsa -q -N "''" -C "'vagrant@ocne'"
  fi
  # Generate known_hosts
  if [[ ! -f /vagrant/known_hosts ]]; then
    msg "Generating shared SSH Known Hosts file"
    echo_do cp /dev/null /vagrant/known_hosts
  fi  
  # Install private key & set permissions
  echo_do "[ -d ~/.ssh ] || ( mkdir ~/.ssh && chmod 0700 ~/.ssh )"
  echo_do "[ -f ~/.ssh/id_rsa ] || ( cp /vagrant/id_rsa ~/.ssh && chmod 0600 ~/.ssh/id_rsa )"
  # Authorise passwordless ssh
  echo_do "[ -f ~/.ssh/id_rsa.pub ] || ( cp /vagrant/id_rsa.pub ~/.ssh && echo_do chmod 0644 ~/.ssh/id_rsa.pub && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys )"
  # SSH Host Keys. Should really use ssh-keyscan -t ecdsa,ed25519
  echo_do eval '[ -f /etc/ssh/ssh_known_hosts ] || echo "`hostname -s`,`hostname -f`,`hostname -I|sed "s/ $//;s/ /,/g"` `cat /etc/ssh/ssh_host_ed25519_key.pub`" >> /vagrant/known_hosts'
  # Last node removes the key
  if [[ ${OPERATOR} == 1 ]]; then
    if [[ -f /vagrant/id_rsa && -f /vagrant/id_rsa.pub ]]; then
      msg "Removing the shared SSH keypair"
      echo_do rm -f /vagrant/id_rsa /vagrant/id_rsa.pub
    fi
    if [[ -f /vagrant/known_hosts ]]; then
      msg "Copying SSH Host Keys to allow StrictHostKeyChecking"
      echo_do "[ -f /etc/ssh/ssh_known_hosts ] || sudo cp /vagrant/known_hosts /etc/ssh/ssh_known_hosts"
      for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
	echo_do ssh "${node}" "sudo cp /vagrant/known_hosts /etc/ssh/ssh_known_hosts"
      done
      msg "Removing the shared SSH Known Hosts file"
      echo_do rm -f /vagrant/known_hosts
    fi
  fi
}

#######################################
# Generate and distribute X.509 Certificates
# Globals:
#   CERT_DIR MASTER MASTERS WORKERS
# Arguments:
#   None
# Returns:
#   None
#######################################
certificates() {
  local nodes

  msg "Generate and deploy X.509 Certificates"
  nodes="${MASTERS},${WORKERS}"

  if [[ ${MASTER} == 0 ]]; then
    # Standalone operator
    nodes="${SUBNET}.100,${nodes}"
  fi
  echo_do sudo /etc/olcne/gen-certs-helper.sh --nodes "${nodes}" --cert-dir "${CERT_DIR}"

  echo_do sudo sed -i -e "'s/^USER=.*/USER=vagrant/'"  ${CERT_DIR}/olcne-tranfer-certs.sh

  echo_do sh -c "'find ${CERT_DIR} -type f -name node.key -exec sudo chmod 0644 {} \;'"

  echo_do bash -ex ${CERT_DIR}/olcne-tranfer-certs.sh

  echo_do sudo /etc/olcne/gen-certs-helper.sh --one-cert --nodes "externalip-validation-webhook-service.externalip-validation-system.svc,externalip-validation-webhook-service.externalip-validation-system.svc.cluster.local" --cert-dir "${EXTERNALIP_VALIDATION_CERT_DIR}"

   echo_do sudo chown -R vagrant: ${EXTERNALIP_VALIDATION_CERT_DIR}
  
}

#######################################
# Bootstrap OCNE
# Globals:
#   CERT_DIR MASTERS WORKERS
# Arguments:
#   None
# Returns:
#   None
#######################################
bootstrap_ocne() {
  local node

  msg "Bootstrap the Oracle Cloud Native Environment Platform Agent on all nodes"
  echo_do sudo /etc/olcne/bootstrap-olcne.sh \
    --secret-manager-type file \
    --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
    --olcne-node-key-path ${CERT_DIR}/production/node.key \
    --olcne-ca-path ${CERT_DIR}/production/ca.cert \
    --olcne-component api-server

  for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
    echo_do ssh "${node}" sudo /etc/olcne/bootstrap-olcne.sh \
      --secret-manager-type file \
      --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
      --olcne-node-key-path ${CERT_DIR}/production/node.key \
      --olcne-ca-path ${CERT_DIR}/production/ca.cert \
      --olcne-component agent
  done
}

#######################################
# Deploy Kubernetes cluster
# Globals:
#   CERT_DIR MASTERS MULTI_MASTER
#   OCNE_CLUSTER_NAME OCNE_ENV_NAME
#   REGISTRY_OCNE NGINX_IMAGE
# Arguments:
#   None
# Returns:
#   None
#######################################
deploy_kubernetes() {
  local node master_nodes worker_nodes
  master_nodes="${MASTERS//,/:8090,}:8090"
  worker_nodes="${WORKERS//,/:8090,}:8090"

  msg "Create the Oracle Cloud Native Environment: ${OCNE_ENV_NAME}"
  echo_do olcnectl environment create \
      --api-server 127.0.0.1:8091 \
      --environment-name "${OCNE_ENV_NAME}" \
      --secret-manager-type file \
      --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
      --olcne-node-key-path ${CERT_DIR}/production/node.key \
      --olcne-ca-path ${CERT_DIR}/production/ca.cert \
      --update-config

  msg "Create the Kubernetes module for ${OCNE_ENV_NAME} "
  if [[ ${MULTI_MASTER} == 0 ]]; then
    # Single master
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --selinux enforcing \
      --module kubernetes --name "${OCNE_CLUSTER_NAME}" \
      --container-registry "${REGISTRY_OCNE}" \
      --nginx-image "${REGISTRY_OCNE}/${NGINX_IMAGE}" \
      --pod-network "${POD_NETWORK}" \
      --pod-network-iface eth1 \
      --control-plane-nodes "${master_nodes}" \
      --worker-nodes "${worker_nodes}" \
      --restrict-service-externalip true \
      --restrict-service-externalip-ca-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/ca.cert \
      --restrict-service-externalip-tls-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.cert \
      --restrict-service-externalip-tls-key=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.key
  else
    # HA Multi-master
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --selinux enforcing \
      --module kubernetes --name "${OCNE_CLUSTER_NAME}" \
      --container-registry "${REGISTRY_OCNE}" \
      --nginx-image "${REGISTRY_OCNE}/${NGINX_IMAGE}" \
      --pod-network "${POD_NETWORK}" \
      --pod-network-iface eth1 \
      --virtual-ip "${SUBNET}.99" \
      --control-plane-nodes "${master_nodes}" \
      --worker-nodes "${worker_nodes}" \
      --restrict-service-externalip true \
      --restrict-service-externalip-ca-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/ca.cert \
      --restrict-service-externalip-tls-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.cert \
      --restrict-service-externalip-tls-key=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.key
  fi

  msg "Validate all required prerequisites are met for the Kubernetes module"
  echo_do olcnectl module validate \
    --environment-name "${OCNE_ENV_NAME}" \
    --name "${OCNE_CLUSTER_NAME}"

  msg "Deploy the Kubernetes module into ${OCNE_ENV_NAME} (Be patient!)"
  echo_do olcnectl module install \
    --environment-name "${OCNE_ENV_NAME}" \
    --name "${OCNE_CLUSTER_NAME}"
}

#######################################
# Deploy additional modules
# Globals:
#   OCNE_CLUSTER_NAME OCNE_ENV_NAME
#   DEPLOY_HELM HELM_MODULE_NAME
#   DEPLOY_ISTIO ISTIO_MODULE_NAME
#   DEPLOY_METALLB METALLB_MODULE_NAME
#   DEPLOY_GLUSTER GLUSTER_MODULE_NAME
#   REGISTRY_OCNE
# Arguments:
#   None
# Returns:
#   None
#######################################
deploy_modules() {
  local node

  msg "Deploying additional modules"

  # Calico networking module
  if [[ ${DEPLOY_CALICO} == 1 ]]; then

    # Create the Calico networking module
    msg "Creating the Calico networking module: ${CALICO_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module calico \
      --name "${CALICO_MODULE_NAME}" \
      --calico-kubernetes-module "${OCNE_CLUSTER_NAME}" \
      --calico-installation-config /vagrant/calico-config.yaml

    # Validate the Calico networking module
    msg "Validating the Calico networking module: ${CALICO_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${CALICO_MODULE_NAME}"

    # Deploy the Calico networking module
    msg "Deploying the Calico module: ${CALICO_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${CALICO_MODULE_NAME}"
  fi

  # Multus networking module
  if [[ ${DEPLOY_MULTUS} == 1 ]]; then

    # Create the Multus networking module
    msg "Creating the Multus networking module: ${MULTUS_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module multus \
      --name "${MULTUS_MODULE_NAME}" \
      --multus-kubernetes-module "${OCNE_CLUSTER_NAME}" \
      --multus-installation-config /vagrant/multus-config.yaml

    # Validate the Multus networking module
    msg "Validating the Multus networking module: ${MULTUS_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${MULTUS_MODULE_NAME}"

    # Deploy the Multus networking module
    msg "Deploying the Multus module: ${MULTUS_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${MULTUS_MODULE_NAME}"
  fi

  # Helm module (deprecated)
  if [[ ${DEPLOY_HELM} == 1 ]]; then

    # Create the Helm module
    msg "Creating the Helm module (deprecated): ${HELM_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module helm \
      --name "${HELM_MODULE_NAME}" \
      --helm-kubernetes-module "${OCNE_CLUSTER_NAME}"

    # Validate the Helm module
    msg "Validating the Helm module: ${HELM_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${HELM_MODULE_NAME}"

    # Deploy the Helm module
    msg "Deploying the Helm module: ${HELM_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${HELM_MODULE_NAME}"
  fi

  # Istio module
  if [[ ${DEPLOY_ISTIO} == 1 ]]; then

    # Create the Istio module
    msg "Creating the Istio module: ${ISTIO_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module istio \
      --name "${ISTIO_MODULE_NAME}" \
      --istio-container-registry "${REGISTRY_OCNE}" \
      --istio-kubernetes-module "${OCNE_CLUSTER_NAME}"

    # Validate the Istio module
    msg "Validating the Istio module: ${ISTIO_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${ISTIO_MODULE_NAME}"

    # Deploy the Istio module
    msg "Deploying the Istio module: ${ISTIO_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${ISTIO_MODULE_NAME}"
  fi

  # MetalLB module
  if [[ ${DEPLOY_METALLB} == 1 ]]; then
    # Create MetalLB Configuration File
    # https://metallb.universe.tf/configuration/
    echo_do "cat <<-EOF | tee /vagrant/metallb-config.yaml
	address-pools:
	- name: default
	  protocol: layer2
	  addresses:
	  - ${SUBNET}.240-${SUBNET}.250
	EOF"
      
    # Create the MetalLB module
    msg "Creating the MetalLB module: ${METALLB_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module metallb \
      --name "${METALLB_MODULE_NAME}" \
      --metallb-kubernetes-module "${OCNE_CLUSTER_NAME}" \
      --metallb-config /vagrant/metallb-config.yaml

    msg "Removing MetalLB temporary configuration file"
    echo_do rm -f /vagrant/metallb-config.yaml
    
    # Validate the MetalLB module
    msg "Validating the MetalLB module: ${METALLB_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${METALLB_MODULE_NAME}"

    # Deploy the MetalLB module
    msg "Deploying the MetalLB module: ${METALLB_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${METALLB_MODULE_NAME}"
  fi

  # Gluster module (using Heketi)
  if [[ ${DEPLOY_GLUSTER} == 1 ]]; then

    # Create the Gluster module
    # using defaults url/user/secret-key: olcnectl module create --module gluster --help
    msg "Creating the Gluster module (deprecated): ${GLUSTER_MODULE_NAME}"
    HEKETI_CLI_SERVER="http://127.0.0.1:8080"
    if [[ ${MASTER} == 0 ]]; then
      # Standalone operator
      HEKETI_CLI_SERVER="http://${SUBNET}.100:8080"
    fi
    echo_do olcnectl module create \
      --environment-name "${OCNE_ENV_NAME}" \
      --module gluster \
      --name "${GLUSTER_MODULE_NAME}" \
      --gluster-kubernetes-module "${OCNE_CLUSTER_NAME}" \
      --gluster-server-url "${HEKETI_CLI_SERVER}"
      
    # Validate the Gluster module
    msg "Validating the Gluster module: ${Gluster_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${GLUSTER_MODULE_NAME}"

    # Deploy the Gluster module
    msg "Deploying the Gluster module: ${GLUSTER_MODULE_NAME} into ${OCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OCNE_ENV_NAME}" \
      --name "${GLUSTER_MODULE_NAME}"
  fi

}

#######################################
# Run Kubernetes fixups
# Globals:
#   MASTERS
# Arguments:
#   None
# Returns:
#   None
#######################################
fixups() {
  local node

  msg "Copying admin.conf for vagrant user on master node(s)"
  for node in ${MASTERS//,/ }; do
    echo_do ssh "${node}" "\"\
      mkdir -p ~/.kube; \
      sudo cp /etc/kubernetes/admin.conf ~/.kube/config; \
      sudo chown $(id -u):$(id -g) ~/.kube/config; \
      echo 'source <(kubectl completion bash)' >> ~/.bashrc; \
      echo 'alias k=kubectl' >> ~/.bashrc; \
      echo 'complete -F __start_kubectl k' >> ~/.bashrc; \
      echo 'command -v helm >/dev/null 2>&1 && source <(helm completion bash)' >> ~/.bashrc; \
      echo 'command -v istioctl >/dev/null 2>&1 && source <(istioctl completion bash)' >> ~/.bashrc; \
      \""
  done

  # Fix: /usr/libexec/crio/conmon doesn't exist
  #      conmon in @ol8_x86_64_appstream overrides @ol8_x86_64_olcne15
  msg "Change conmon from /usr/libexec/crio/conmon to /usr/bin/conmon in /etc/crio/crio.conf"
  for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
    echo_do ssh "${node}" "\"\
      sudo sed 's|/usr/libexec/crio/conmon|/usr/bin/conmon|' -i /etc/crio/crio.conf \
      && sudo systemctl restart crio.service \
    \""
  done  

  msg "Starting kubectl proxy service on master nodes"
  for node in ${MASTERS//,/ }; do
    # Expose the kubectl proxy to the host
    echo_do ssh "${node}" "\"\
        sudo sed -i.bak 's/KUBECTL_PROXY_ARGS=--port 8001/KUBECTL_PROXY_ARGS=--port 8001 --accept-hosts=.* --address=0.0.0.0/' \
            /etc/systemd/system/kubectl-proxy.service.d/10-kubectl-proxy.conf \
        && sudo systemctl daemon-reload \
        && sudo systemctl enable --now kubectl-proxy.service \
    \""
  done

  # Fix: kubelet: "Unable to read config path" err="path does not exist, ignoring" path="/etc/kubernetes/manifests"
  msg "Creating empty /etc/kubernetes/manifests directory on worker nodes"
  for node in ${WORKERS//,/ }; do
    echo_do ssh "${node}" "\"\
      [ -d /etc/kubernetes/manifests ] || sudo mkdir /etc/kubernetes/manifests
    \""
  done
  
  # Fix: kubelet: summary_sys_containers.go: "Failed to get system container stats"
  #               err='failed to get cgroup stats for "/system.slice/kubelet.service":
  #                    failed to get container info for "/system.slice/kubelet.service":
  #                    unknown container "/system.slice/kubelet.service"'
  #               containerName="/system.slice/kubelet.service"
  msg "Creating /etc/systemd/system/kubelet.service.d/11-cgroups.conf on K8s nodes"
  for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
    echo_do ssh "${node}" "\"\
      { cat <<-EOF | sudo tee /etc/systemd/system/kubelet.service.d/11-cgroups.conf
	[Service]
	CPUAccounting=true
	MemoryAccounting=true
	EOF
      } \
      && sudo systemctl daemon-reload \
      && sudo systemctl restart kubelet \
    \""
  done  

  # Fix: audit: type=1400 avc:  denied  { ioctl } for  comm="iptables" path="/sys/fs/cgroup" dev="tmpfs"
  msg "Fix AVC Denial on iptables"
  for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
    echo_do ssh "${node}" "\"\
      echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /tmp/local_iptables.cil \
      && sudo semodule -i /tmp/local_iptables.cil \
      && rm -f /tmp/local_iptables.cil
    \""
  done
  
  # Fix: Keepalived_vrrp: (VI_1) WARNING - equal priority advert received from remote host with our IP address.
  if [[ ${MULTI_MASTER} == 1 ]]; then
    msg "Fix Keepalived: remove unicast_src_ip from unicast_peers"
    for node in ${MASTERS//,/ }; do
      echo_do ssh "${node}" "\"\
        sudo perl -i -ne 'print unless /^\s*$node\s*$/' /etc/keepalived/keepalived.conf \
	&& sudo systemctl restart keepalived.service
      \""
    done
  fi

  # Fix: heketi: systemd[1]: /usr/lib/systemd/system/glusterd.service:21: Unknown lvalue 'StartLimitIntervalSec' in section 'Service'
  if [[ ${DEPLOY_GLUSTER} == 1 ]]; then
    msg "Removing StartLimitIntervalSec from /usr/lib/systemd/system/glusterd.service on Gluster nodes"
    for node in ${WORKERS//,/ }; do
      echo_do ssh "${node}" "\"\
        sudo sed -i '/^StartLimitIntervalSec=/d' /usr/lib/systemd/system/glusterd.service \
	&& sudo systemctl daemon-reload \
        && sudo systemctl restart glusterd.service \
      \""
    done

    # Check if number of Gluster servers (Worker nodes) is less than 3, and patch K8s StorageClass. Default is 3 replicas.
    NB_WORKERS=$(echo ${WORKERS} | awk -F',' '{print NF}')
    if [[ ${NB_WORKERS} -lt "3" ]]; then
      # https://kubernetes.io/docs/concepts/storage/storage-classes/#glusterfs
      # https://github.com/kubernetes/examples/blob/master/staging/persistent-volume-provisioning/README.md
      volumetype="none" # Distribute volume
      if [[ ${NB_WORKERS} == "2" ]]; then
	  volumetype="replicate:2" # 2 replicas
      fi      
      msg "Patching the Kubernetes hyperconverged storageclass volumetype to $volumetype"
      node=${MASTERS//,*/}
      # K8s Storage Classes are immutable. Cannot: kubectl patch storageclasses hyperconverged -p '{"Parameters":{"volumetype":"replicate:2"}}'
      echo_do ssh "${node}" "\"\
        kubectl get storageclasses hyperconverged -o=yaml | yq w - parameters.volumetype $volumetype > /vagrant/hyperconverged.yaml \
	&& kubectl replace -f /vagrant/hyperconverged.yaml --force \
	&& rm -f /vagrant/hyperconverged.yaml \
      \""
    fi
  fi

  nodes="${MASTERS},${WORKERS}"
  if [[ ${MASTER} == 0 ]]; then
    nodes="${SUBNET}.100,${nodes}"
  fi

  # Fix: systemd: Started Session XX of user vagrant / session-XX.scope:
  #      systemd-logind: New session XX of user vagrant / Session XX logged out / Removed session XX
  # https://access.redhat.com/solutions/1564823
  msg "Create discard filter to suppress user / session log entries in /var/log/messages"
  echo 'if $programname == "systemd" and ($msg contains "Started Session" or $msg contains "scope: Succeeded") then stop' > /vagrant/ignore-systemd-session-slice.conf
  echo 'if $programname == "systemd-logind" and ($msg contains "New session" or $msg contains "logged out. Waiting for processes to exit" or $msg contains "Removed session") then stop' > /vagrant/ignore-systemd-logind-session.conf
  for node in ${nodes//,/ }; do
    echo_do ssh "${node}" "\"\
      sudo cp /vagrant/ignore-systemd-session-slice.conf /etc/rsyslog.d/ \
      && sudo cp /vagrant/ignore-systemd-logind-session.conf /etc/rsyslog.d/ \
      && sudo systemctl restart rsyslog \
      \""
  done
  echo_do rm -f /vagrant/ignore-systemd-session-slice.conf
  echo_do rm -f /vagrant/ignore-systemd-logind-session.conf

  # Fix: firewalld: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option.
  for node in ${nodes//,/ }; do
    echo_do ssh "${node}" "\"\
      sudo sed -i 's/AllowZoneDrifting=yes/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf \
      && (sudo systemctl reload firewalld.service; true) \
      \""
  done
  
}

#######################################
# Cluster ready!
# Globals:
#   MASTERS
# Arguments:
#   None
# Returns:
#   None
#######################################
ready() {
  local node

  msg "Your Oracle Cloud Native Environment is operational."
  node=${MASTERS//,*/}
  ssh vagrant@"${node}" kubectl get nodes
}

#######################################
# Main
#######################################
main () {
  parse_args "$@"
  clean_networking
  setup_repos
  requirements
  install_packages
  passwordless_ssh
  msg "Oracle Linux base software installation complete."
  # All nodes are up, orchestrate installation
  if [[ ${OPERATOR} == 1 ]]; then
    certificates
    bootstrap_ocne
    deploy_kubernetes
    deploy_modules
    fixups
    ready
  fi
}

main "$@"

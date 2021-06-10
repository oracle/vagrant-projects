#!/bin/bash
#
# Provision Oracle Linux Cloud Native Environment nodes
#
# Copyright (c) 2019, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Description: Installs the Oracle Linux Cloud Native Environment packages,
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
#   OLCNE_DEV OLCNE_VERSION K8S_VERSION MASTER MASTERS WORKER WORKERS
#   OPERATOR MULTI_MASTER REGISTRY_OLCNE VERBOSE EXTRA_REPO
#   NGINX_IMAGE
# Arguments:
#   Command line
# Returns:
#   None
#######################################
parse_args() {
  OLCNE_CLUSTER_NAME='' OLCNE_ENV_NAME='' OLCNE_DEV=0 OLCNE_VERSION='' REGISTRY_OLCNE=''
  OPERATOR=0 MULTI_MASTER=0 MASTER=0 MASTERS='' WORKER=0 WORKERS=''
  VERBOSE=0 EXTRA_REPO='' NGINX_IMAGE=''
  DEPLOY_HELM=0 HELM_MODULE_NAME='' DEPLOY_ISTIO=0 ISTIO_MODULE_NAME=''

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
      "--olcne-dev")
        OLCNE_DEV=1
        shift
        ;;
      "--olcne-environment-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --olcne-environment-name" >&2
          exit 1
        fi
        OLCNE_ENV_NAME="$2"
        shift; shift;
        ;;
      "--olcne-cluster-name")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --olcne-cluster-name" >&2
          exit 1
        fi
        OLCNE_CLUSTER_NAME="$2"
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
      "--registry-olcne")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --registry-olcne" >&2
	        exit 1
        fi
        REGISTRY_OLCNE="$2"
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
        DEPLOY_HELM=1
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

  readonly OLCNE_CLUSTER_NAME OLCNE_ENV_NAME OLCNE_DEV REGISTRY_OLCNE
  readonly OPERATOR MULTI_MASTER MASTER MASTERS WORKER WORKERS
  readonly VERBOSE EXTRA_REPO NGINX_IMAGE
  readonly DEPLOY_HELM HELM_MODULE_NAME DEPLOY_ISTIO ISTIO_MODULE_NAME
}

#######################################
# Configure repos for the installation
# Globals:
#   EXTRA_REPO
#   OLCNE_DEV
# Arguments:
#   None
# Returns:
#   None
#######################################
setup_repos() {
  msg "Configure repos for Oracle Linux Cloud Native Environment"

  # Add OLCNE release package
  echo_do dnf install -y oracle-olcne-release-el8
  echo_do dnf config-manager --enable ol8_olcne13 ol8_addons ol8_baseos_latest ol8_UEKR6
  echo_do dnf config-manager --disable ol8_olcne12

  # Optional extra repo
  if [[ -n ${EXTRA_REPO} ]]; then echo_do dnf config-manager --add-repo "${EXTRA_REPO}"; fi

  # Enable OLCNE developer channel
  if [[ ${OLCNE_DEV} == 1 ]]; then echo_do dnf config-manager --enable ol8_developer_olcne; fi
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

  nmcli con del "Wired connection 1"

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
  # Swap
  echo_do swapoff -a
  echo_do sed -i "'/ swap /d'" /etc/fstab

  # Bridge filtering
  echo_do modprobe br_netfilter
  echo_do eval "echo 'br_netfilter' > /etc/modules-load.d/br_netfilter.conf"

  # Enable & start firewalld; add eth0 to the public zone
  echo_do systemctl enable --now firewalld
  echo_do firewall-cmd --permanent --zone=public --add-interface=eth0
}

#######################################
# Install packages on the node
# Note: As of OLCNE 1.0.1 kubernetes packages are deployed automatically.
# We are still installing them to be able to customize the configuration for
# the vagrant environment.
# Globals:
#   OPERATOR OLCNE_VERSION MASTER WORKER K8S_VERSION MULTI_MASTER
#   REGISTRY_OLCNE NGINX_IMAGE
# Arguments:
#   None
# Returns:
#   None
#######################################
install_packages() {

  if [[ ${OPERATOR} == 1 ]]; then
    msg "Installing the Oracle Linux Cloud Native Environment Platform API Server and Platform CLI tool to the operator node."
    echo_do dnf install -y olcnectl"${OLCNE_VERSION}" olcne-api-server"${OLCNE_VERSION}" olcne-utils"${OLCNE_VERSION}"
    echo_do systemctl enable olcne-api-server.service
    echo_do firewall-cmd --add-port=8091/tcp --permanent
    echo_do firewall-cmd --add-masquerade --permanent
  fi
  if [[ ${MASTER} == 1 || ${WORKER} == 1 ]]; then
    msg "Installing the Oracle Linux Cloud Native Environment Platform Agent"
    echo_do dnf install -y olcne-agent"${OLCNE_VERSION}" olcne-utils"${OLCNE_VERSION}"
    echo_do systemctl enable olcne-agent.service
    if [[ -n ${HTTP_PROXY} ]]; then
      # CRI-O proxies
      mkdir -p /etc/systemd/system/crio.service.d
      cat > /etc/systemd/system/crio.service.d/crio-proxy.conf <<-EOF
	[Service]
	Environment="HTTP_PROXY=${HTTP_PROXY}"
	Environment="HTTPS_PROXY=${HTTPS_PROXY}"
	Environment="NO_PROXY=${NO_PROXY}"
	EOF
    fi
    echo_do firewall-cmd --add-masquerade --permanent
    echo_do firewall-cmd --zone=trusted --add-interface=cni0 --permanent
    echo_do firewall-cmd --add-port=8090/tcp --permanent
    echo_do firewall-cmd --add-port=10250/tcp --permanent
    echo_do firewall-cmd --add-port=10255/tcp --permanent
    echo_do firewall-cmd --add-port=8472/udp --permanent
    echo_do firewall-cmd --add-port=30000-32767/tcp --permanent
  fi

  if [[ ${MASTER} == 1 ]]; then
    echo_do dnf install -y bash-completion
    echo_do firewall-cmd --add-port=6443/tcp --permanent
    echo_do firewall-cmd --add-port=8001/tcp --permanent
    # OLCNE 1.0.1 requires these ports for single master as well
    echo_do firewall-cmd --add-port=10251/tcp --permanent
    echo_do firewall-cmd --add-port=10252/tcp --permanent
    echo_do firewall-cmd --add-port=2379/tcp --permanent
    echo_do firewall-cmd --add-port=2380/tcp --permanent
    # Software load balancer firewall rules
    echo_do firewall-cmd --add-port=6444/tcp --permanent
    echo_do firewall-cmd --add-protocol=vrrp --permanent

  fi

  # Reload firewalld
  echo_do firewall-cmd --reload
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
  if [[ ! -f /vagrant/id_rsa ]]; then
    msg "Generating shared SSH keypair"
    echo_do ssh-keygen -t rsa -f /vagrant/id_rsa -q -N "''"
  fi
  # Install private key
  echo_do mkdir -p /root/.ssh
  echo_do cp /vagrant/id_rsa /root/.ssh/
  # Authorise passwordless ssh
  echo_do cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
  echo_do eval "cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys"
  # Don't do host checking
  cat > ~/.ssh/config <<-EOF
	Host operator* master* worker* 192.168.99.*
	  StrictHostKeyChecking no
	  UserKnownHostsFile /dev/null
	  LogLevel QUIET
	EOF
  # Set permissions
  echo_do chmod 0700 /root/.ssh
  echo_do chmod 0600 /root/.ssh/authorized_keys /root/.ssh/id_rsa
  # Last node removes the key
  if [[ ${OPERATOR} == 1 ]]; then
    msg "Removing the shared SSH keypair"
    echo_do rm /vagrant/id_rsa /vagrant/id_rsa.pub
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
    nodes="192.168.99.100,${nodes}"
  fi
  echo_do /etc/olcne/gen-certs-helper.sh --nodes "${nodes}"  --cert-dir "${CERT_DIR}"

  echo_do sed -i -e "'s/^USER=.*/USER=vagrant/'"  ${CERT_DIR}/olcne-tranfer-certs.sh

  echo_do bash -e ${CERT_DIR}/olcne-tranfer-certs.sh

  echo_do /etc/olcne/gen-certs-helper.sh --one-cert --nodes "externalip-validation-webhook-service.externalip-validation-system.svc,externalip-validation-webhook-service.externalip-validation-system.svc.cluster.local" --cert-dir "${EXTERNALIP_VALIDATION_CERT_DIR}"

}

#######################################
# Bootstrap OLCNE
# Globals:
#   CERT_DIR MASTERS WORKERS
# Arguments:
#   None
# Returns:
#   None
#######################################
bootstrap_olcne() {
  local node

  msg "Bootstrap the Oracle Linux Cloud Native Environment Platform Agent on all nodes"
  echo_do /etc/olcne/bootstrap-olcne.sh \
    --secret-manager-type file \
    --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
    --olcne-ca-path ${CERT_DIR}/production/ca.cert \
    --olcne-node-key-path ${CERT_DIR}/production/node.key \
    --olcne-component api-server

  for node in ${MASTERS//,/ } ${WORKERS//,/ }; do
    echo_do ssh "${node}" /etc/olcne/bootstrap-olcne.sh \
      --secret-manager-type file \
      --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
      --olcne-ca-path ${CERT_DIR}/production/ca.cert \
      --olcne-node-key-path ${CERT_DIR}/production/node.key \
      --olcne-component agent
  done
}

#######################################
# Deploy Kubernetes cluster
# Globals:
#   CERT_DIR MASTERS MULTI_MASTER
#   OLCNE_CLUSTER_NAME OLCNE_ENV_NAME
#   REGISTRY_OLCNE NGINX_IMAGE
# Arguments:
#   None
# Returns:
#   None
#######################################
deploy_kubernetes() {
  local node master_nodes worker_nodes
  master_nodes="${MASTERS//,/:8090,}:8090"
  worker_nodes="${WORKERS//,/:8090,}:8090"

  msg "Create the Oracle Linux Cloud Native Environment: ${OLCNE_ENV_NAME}"
  echo_do olcnectl --api-server 127.0.0.1:8091 environment create \
      --environment-name "${OLCNE_ENV_NAME}" \
      --secret-manager-type file \
      --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
      --olcne-ca-path ${CERT_DIR}/production/ca.cert \
      --olcne-node-key-path ${CERT_DIR}/production/node.key \
      --update-config

  msg "Create the Kubernetes module for ${OLCNE_ENV_NAME} "
  if [[ ${MULTI_MASTER} == 0 ]]; then
    # Single master
    echo_do olcnectl module create \
      --environment-name "${OLCNE_ENV_NAME}" \
      --selinux enforcing \
      --module kubernetes --name "${OLCNE_CLUSTER_NAME}" \
      --container-registry "${REGISTRY_OLCNE}" \
      --nginx-image "${REGISTRY_OLCNE}/${NGINX_IMAGE}" \
      --pod-network-iface eth1 \
      --master-nodes "${master_nodes}" \
      --worker-nodes "${worker_nodes}" \
      --restrict-service-externalip-ca-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/ca.cert \
      --restrict-service-externalip-tls-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.cert \
      --restrict-service-externalip-tls-key=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.key
  else
    # HA Multi-master
    echo_do olcnectl module create \
      --environment-name "${OLCNE_ENV_NAME}" \
      --selinux enforcing \
      --module kubernetes --name "${OLCNE_CLUSTER_NAME}" \
      --container-registry "${REGISTRY_OLCNE}" \
      --nginx-image "${REGISTRY_OLCNE}/${NGINX_IMAGE}" \
      --pod-network-iface eth1 \
      --virtual-ip 192.168.99.99 \
      --master-nodes "${master_nodes}" \
      --worker-nodes "${worker_nodes}" \
      --restrict-service-externalip-ca-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/ca.cert \
      --restrict-service-externalip-tls-cert=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.cert \
      --restrict-service-externalip-tls-key=${EXTERNALIP_VALIDATION_CERT_DIR}/production/node.key
  fi

  msg "Validate all required prerequisites are met for the Kubernetes module"
  echo_do olcnectl module validate \
    --environment-name "${OLCNE_ENV_NAME}" \
    --name "${OLCNE_CLUSTER_NAME}"

  msg "Deploy the Kubernetes module into ${OLCNE_ENV_NAME} (Be patient!)"
  echo_do olcnectl module install \
    --environment-name "${OLCNE_ENV_NAME}" \
    --name "${OLCNE_CLUSTER_NAME}"
}

#######################################
# Deploy additional modules
# Globals:
#   OLCNE_CLUSTER_NAME OLCNE_ENV_NAME
#   DEPLOY_HELM HELM_MODULE_NAME
#   DEPLOY_ISTIO ISTIO_MODULE_NAME
#   REGISTRY_OLCNE
# Arguments:
#   None
# Returns:
#   None
#######################################
deploy_modules() {
  local node

  msg "Deploying additional modules"

  # Helm module
  if [[ ${DEPLOY_HELM} == 1 ]]; then

    # Create the Helm module
    msg "Creating the Helm module: ${HELM_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OLCNE_ENV_NAME}" \
      --module helm \
      --name "${HELM_MODULE_NAME}" \
      --helm-kubernetes-module "${OLCNE_CLUSTER_NAME}"

    # Validate the Helm module
    msg "Validating the Helm module: ${HELM_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OLCNE_ENV_NAME}" \
      --name "${HELM_MODULE_NAME}"

    # Deploy the Helm module
    msg "Deploying the Helm module: ${HELM_MODULE_NAME} into ${OLCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OLCNE_ENV_NAME}" \
      --name "${HELM_MODULE_NAME}"
  fi

  # Istio module
  if [[ ${DEPLOY_ISTIO} == 1 ]]; then

    # Create the Istio module
    msg "Creating the Istio module: ${ISTIO_MODULE_NAME}"
    echo_do olcnectl module create \
      --environment-name "${OLCNE_ENV_NAME}" \
      --module istio \
      --name "${ISTIO_MODULE_NAME}" \
      --istio-container-registry "${REGISTRY_OLCNE}" \
      --istio-helm-module "${HELM_MODULE_NAME}"


    # Validate the Istio module
    msg "Validating the Istio module: ${ISTIO_MODULE_NAME}"
    echo_do olcnectl module validate \
      --environment-name "${OLCNE_ENV_NAME}" \
      --name "${ISTIO_MODULE_NAME}"

    # Deploy the Istio module
    msg "Deploying the Istio module: ${ISTIO_MODULE_NAME} into ${OLCNE_CLUSTER_NAME}"
    echo_do olcnectl module install \
      --environment-name "${OLCNE_ENV_NAME}" \
      --name "${ISTIO_MODULE_NAME}"
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
      mkdir -p ~vagrant/.kube; \
      cp /etc/kubernetes/admin.conf ~vagrant/.kube/config; \
      chown -R vagrant: ~vagrant/.kube; \
      echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc; \
      echo 'alias k=kubectl' >> ~vagrant/.bashrc; \
      echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc; \
      \""
  done

  msg "Starting kubectl proxy service on master nodes"
  for node in ${MASTERS//,/ }; do
    # Expose the kubectl proxy to the host
    echo_do ssh "${node}" "\"\
        sed -i.bak 's/KUBECTL_PROXY_ARGS=--port 8001/KUBECTL_PROXY_ARGS=--port 8001 --accept-hosts=.* --address=0.0.0.0/' \
            /etc/systemd/system/kubectl-proxy.service.d/10-kubectl-proxy.conf \
        && systemctl daemon-reload \
        && systemctl enable --now kubectl-proxy.service \
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

  msg "Your Oracle Linux Cloud Native Environment is operational."
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
    bootstrap_olcne
    deploy_kubernetes
    deploy_modules
    fixups
    ready
  fi
}

main "$@"

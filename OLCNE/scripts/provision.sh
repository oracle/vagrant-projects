#!/bin/bash
#
# Provision Oracle Linux Cloud Native Environment nodes
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
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
readonly OLCNE_CLUSTER="olcne-cluster"
readonly OLCNE_ENV="olcne-env"

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

  [[ -n "${VERBOSE}" ]] && echo "    $@"
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
  echo "===== ${@} ====="
}

#######################################
# Parse arguments
# Exit on error.
# Globals:
#   OLCNE_DEV OLCNE_VERSION K8S_VERSION MASTER MASTERS WORKER WORKERS
#   OPERATOR MULTI_MASTER REGISTRY_K8S REGISTRY_OLCNE VERBOSE EXTRA_REPO
#   NGINX_IMAGE IP_ADDR
# Arguments:
#   Command line
# Returns:
#   None
#######################################
parse_args() {
  OLCNE_DEV= OLCNE_VERSION= K8S_VERSION= MASTER= MASTERS= WORKER= WORKERS=
  OPERATOR= MULTI_MASTER= REGISTRY_K8S= REGISTRY_OLCNE= VERBOSE= EXTRA_REPO=
  NGINX_IMAGE= IP_ADDR=

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
      "--olcne-version")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --olcne-version" >&2
          exit 1
        fi
        OLCNE_VERSION="-$2"
        shift; shift
        ;;
      "--k8s-version")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --k8s-version" >&2
          exit 1
        fi
        K8S_VERSION="-$2"
        shift; shift
        ;;
      "--nginx-image")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --nginx-image" >&2
          exit 1
        fi
        NGINX_IMAGE="$2"
        shift; shift
        ;;
      "--ip-addr")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --ip-addr" >&2
          exit 1
        fi
        IP_ADDR="$2"
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
      "--registry-k8s")
        if [[ $# -lt 2 ]]; then
          echo "Missing parameter for --registry-k8s" >&2
	  exit 1
        fi
        REGISTRY_K8S="$2"
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

  readonly OLCNE_DEV OLCNE_VERSION K8S_VERSION MASTER MASTERS WORKER WORKERS
  readonly OPERATOR MULTI_MASTER REGISTRY_K8S REGISTRY_OLCNE VERBOSE EXTRA_REPO
  readonly NGINX_IMAGE IP_ADDR
}

#######################################
# Configure yum repos for the installation
# Globals:
#   EXTRA_REPO
#   OLCNE_DEV
# Arguments:
#   None
# Returns:
#   None
#######################################
setup_repos() {
  msg "Configure YUM repos for Oracle Linux Cloud Native Environment"

  # Install jq (OCI requirement)
  echo_do yum install -y jq

  # Install the yum-utils package for repo selection
  echo_do yum install -y yum-utils

  # Add OLCNE channel
  echo_do yum install -y oracle-olcne-release-el7

  # Disable Developer channels
  echo_do yum-config-manager --disable ol7_developer\*

  # Enable kvm_utils
  echo_do yum-config-manager --enable ol7_kvm_utils

  # Optional extra repo
  [[ -n "${EXTRA_REPO}" ]] && echo_do yum-config-manager --add-repo "${EXTRA_REPO}"

  # Enable OLCNE developer channel
  [[ -n "${OLCNE_DEV}" ]] && echo_do yum-config-manager --enable ol7_developer_olcne
}

#######################################
# Configure private network interface
# Globals:
#   IP_ADDR
# Arguments:
#   None
# Returns:
#   None
#######################################
setup_networking() {
  msg "Configure private network"

  cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<-EOF
	NM_CONTROLLED=n
	BOOTPROTO=none
	ONBOOT=yes
	IPADDR=${IP_ADDR}
	NETMASK=255.255.255.0
	DEVICE=eth1
	PEERDNS=no
	IPV6INIT=no
	EOF

  echo_do ifup eth1
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

  # SeLinux to Permissive
  echo_do /usr/sbin/setenforce 0
  echo_do sed -i "'s/^SELINUX=.*/SELINUX=permissive/g'" /etc/selinux/config

  # Enable & start firewalld
  echo_do systemctl enable --now firewalld
}

#######################################
# Install packages on the node
# Note: As of OLCNE 1.0.1 kubernetes packages are deployed automatically.
# We are still installing them to be able to customize the configuration for
# the vagrant environment.
# Globals:
#   OPERATOR OLCNE_VERSION MASTER WORKER K8S_VERSION MULTI_MASTER
# Arguments:
#   None
# Returns:
#   None
#######################################
install_packages() {
  local ip_addr kubelet_node ExecStart

  if [[ -n "${OPERATOR}" ]]; then
    msg "Installing the Oracle Linux Cloud Native Environment Platform API Server and Platform CLI tool to the operator node."
    echo_do yum install -y olcnectl${OLCNE_VERSION} olcne-api-server${OLCNE_VERSION} olcne-utils${OLCNE_VERSION}
    echo_do systemctl enable olcne-api-server.service
    echo_do firewall-cmd --add-port=8091/tcp --permanent
    echo_do firewall-cmd --add-masquerade --permanent
  fi
  if [[ -n "${MASTER}" || -n "${WORKER}" ]]; then
    msg "Installing the Oracle Linux Cloud Native Environment Platform Agent"
    echo_do yum install -y olcne-agent${OLCNE_VERSION} olcne-utils${OLCNE_VERSION}
    echo_do yum install -y kubeadm${K8S_VERSION} kubelet${K8S_VERSION} kubectl${K8S_VERSION}
    echo_do sysctl -p /etc/sysctl.d/k8s.conf
    echo_do systemctl enable olcne-agent.service
    if [[ -n "${HTTP_PROXY}" ]]; then
      # CRI-O proxies
      mkdir /etc/systemd/system/crio.service.d
      cat > /etc/systemd/system/crio.service.d/crio-proxy.conf <<-EOF
	[Service]
	Environment="HTTP_PROXY=${HTTP_PROXY}"
	Environment="HTTPS_PROXY=${HTTPS_PROXY}"
	Environment="NO_PROXY=${NO_PROXY}"
	EOF
    fi
    echo_do firewall-cmd --add-masquerade --permanent
    echo_do firewall-cmd --add-port=8090/tcp --permanent
    echo_do firewall-cmd --add-port=10250/tcp --permanent
    echo_do firewall-cmd --add-port=10255/tcp --permanent
    echo_do firewall-cmd --add-port=8472/udp --permanent
    echo_do firewall-cmd --add-port=30000-32767/tcp --permanent
    # Ensure kubelet uses the right interface
    ip_addr=$(ip addr | awk -F'[ /]+' '/192.168.99.255/ {print $3}')
    kubelet_node="/etc/systemd/system/kubelet.service.d/90-node-ip.conf"
    ExecStart=$(grep ExecStart=/ /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | sed -e 's/\$KUBELET_EXTRA_ARGS/\$KUBELET_EXTRA_ARGS \$KUBELET_NODE_IP_ADDR_ARGS/')
    cat <<-EOF >${kubelet_node}
	[Service]
	Environment="KUBELET_NODE_IP_ADDR_ARGS=--node-ip=${ip_addr}"
	ExecStart=
	${ExecStart}
	EOF
    chmod 644 ${kubelet_node}
    systemctl daemon-reload
  fi
  if [[ -n "${MASTER}" ]]; then
    echo_do yum install -y bash-completion
    echo_do firewall-cmd --add-port=6443/tcp --permanent
    # Expose the kubectl proxy to the host
    sed -i 's/"KUBECTL_PROXY_ARGS=.*"/"KUBECTL_PROXY_ARGS=--port 8001 --accept-hosts='.*' --address=0.0.0.0"/' \
      /etc/systemd/system/kubectl-proxy.service.d/10-kubectl-proxy.conf
    echo_do firewall-cmd --add-port=8001/tcp --permanent
    echo_do systemctl enable kubectl-proxy.service
    # OLCNE 1.0.1 requires these ports for single master as well
    echo_do firewall-cmd --add-port=10251/tcp --permanent
    echo_do firewall-cmd --add-port=10252/tcp --permanent
    echo_do firewall-cmd --add-port=2379/tcp --permanent
    echo_do firewall-cmd --add-port=2380/tcp --permanent
    if [[ -n "${MULTI_MASTER}" ]]; then
      # Multi-master load balancer
      echo_do yum install -y olcne-nginx keepalived
      echo_do firewall-cmd --add-port=6444/tcp --permanent
      echo_do firewall-cmd --add-protocol=vrrp --permanent
      if [[ -n "${HTTP_PROXY}" ]]; then
        # NGINX proxies
        mkdir /etc/systemd/system/olcne-nginx.service.d
        cat > /etc/systemd/system/olcne-nginx.service.d/proxy.conf <<-EOF
		[Service]
		Environment="HTTP_PROXY=${HTTP_PROXY}"
		Environment="HTTPS_PROXY=${HTTPS_PROXY}"
		Environment="NO_PROXY=${NO_PROXY}"
		EOF
      fi
    fi
  fi

  # Restart firewalld
  echo_do systemctl restart firewalld
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
    echo_do ssh-keygen -t rsa -f /vagrant/id_rsa -q -N "''"
  fi
  # Install private key
  echo_do mkdir ~/.ssh
  echo_do cp /vagrant/id_rsa ~/.ssh/
  # Authorise passwordless ssh
  echo_do cp /vagrant/id_rsa.pub ~/.ssh/authorized_keys
  echo_do eval "cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys"
  # Don't do host checking
  cat > ~/.ssh/config <<-EOF
	Host operator* master* worker* 192.168.99.*
	  StrictHostKeyChecking no
	  UserKnownHostsFile /dev/null
	  LogLevel QUIET
	EOF
  # Set permissions
  echo_do chmod -R 0600 ~/.ssh
  # Last node removes the key
  [[ -n "${OPERATOR}" ]] && echo_do rm /vagrant/id_rsa /vagrant/id_rsa.pub
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
  nodes=$(echo ${MASTERS} ${WORKERS} | sed -e "s/ /,/g")
  if [[ -z "${MASTER}" ]]; then
    # Standalone operator
    nodes="192.168.99.100,${nodes}"
  fi
  echo_do /etc/olcne/gen-certs-helper.sh --nodes ${nodes}  --cert-dir ${CERT_DIR}

  echo_do sed -i -e "'s/^USER=.*/USER=vagrant/'"  ${CERT_DIR}/olcne-tranfer-certs.sh

  echo_do bash -e ${CERT_DIR}/olcne-tranfer-certs.sh
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

  for node in ${MASTERS} ${WORKERS}; do
    echo_do ssh ${node} /etc/olcne/bootstrap-olcne.sh \
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
#   CERT_DIR MASTERS MULTI_MASTER OLCNE_CLUSTER OLCNE_ENV
#   REGISTRY_K8S REGISTRY_OLCNE NGINX_IMAGE
# Arguments:
#   None
# Returns:
#   None
#######################################
deploy_kubernetes() {
  local node gateway

  msg "Create the Oracle Linux Cloud Native Environment: ${OLCNE_ENV}"
  echo_do olcnectl --api-server 127.0.0.1:8091 environment create \
      --environment-name ${OLCNE_ENV} \
      --secret-manager-type file \
      --olcne-node-cert-path ${CERT_DIR}/production/node.cert \
      --olcne-ca-path ${CERT_DIR}/production/ca.cert \
      --olcne-node-key-path ${CERT_DIR}/production/node.key \
      --update-config

  msg "Create the Kubernetes module for ${OLCNE_ENV} "
  if [[ -z "${MULTI_MASTER}" ]]; then
    # Single master
    echo_do olcnectl module create \
      --environment-name ${OLCNE_ENV} \
      --module kubernetes --name ${OLCNE_CLUSTER} \
      ${REGISTRY_K8S:+--container-registry $REGISTRY_K8S} \
      --apiserver-advertise-address $(echo ${MASTERS} | sed -e "s/.* //") \
      --master-nodes $(echo ${MASTERS} | sed -e "s/ /:8090,/g" -e "s/$/:8090/")\
      --worker-nodes $(echo ${WORKERS} | sed -e "s/ /:8090,/g" -e "s/$/:8090/")
  else
    # HA Multi-master
    echo_do olcnectl module create \
      --environment-name ${OLCNE_ENV} \
      --module kubernetes --name ${OLCNE_CLUSTER} \
      ${REGISTRY_K8S:+--container-registry $REGISTRY_K8S} \
      --virtual-ip 192.168.99.99 \
      ${REGISTRY_OLCNE:+--nginx-image $REGISTRY_OLCNE/$NGINX_IMAGE} \
      --master-nodes $(echo ${MASTERS} | sed -e "s/ /:8090,/g" -e "s/$/:8090/")\
      --worker-nodes $(echo ${WORKERS} | sed -e "s/ /:8090,/g" -e "s/$/:8090/")
  fi

  msg "Validate all required prerequisites are met for the Kubernetes module"
  echo_do olcnectl module validate \
    --environment-name ${OLCNE_ENV} \
    --name ${OLCNE_CLUSTER}

  if [[ -n "${MULTI_MASTER}" ]]; then
    # Force the routing through eth1 during setup (Workaround for OLCNE-1028)
    if [[ -z "${MASTER}" ]]; then
      # Standalone operator
      msg "Set masters default route on eth1 via the operator node"
      gateway="192.168.99.100"
    else
      msg "Set masters default route on eth1 via worker1"
      gateway=$(echo ${WORKERS} | sed -e 's/ .*//')
    fi
    
    for node in ${MASTERS}; do
      echo_do ssh ${node} "\"\
        ip route list 0/0 | grep -q default && ip route del default; \
        ip route add default via ${gateway} dev eth1; \
	grep -q DEFROUTE /etc/sysconfig/network-scripts/ifcfg-eth0 || \
	  echo 'DEFROUTE=no' >> /etc/sysconfig/network-scripts/ifcfg-eth0; \
	grep -q GATEWAY /etc/sysconfig/network-scripts/ifcfg-eth1 || \
	  echo 'GATEWAY=${gateway}' >> /etc/sysconfig/network-scripts/ifcfg-eth1; \
        \""
    done
  fi

  msg "Deploy the Kubernetes module into ${OLCNE_ENV} (Be patient!)"
  echo_do olcnectl module install \
    --environment-name ${OLCNE_ENV} \
    --name ${OLCNE_CLUSTER}
}

#######################################
# Run fixups
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
  for node in ${MASTERS}; do
    echo_do ssh ${node} "\"\
      mkdir -p ~vagrant/.kube; \
      cp /etc/kubernetes/admin.conf ~vagrant/.kube/config; \
      chown -R vagrant: ~vagrant/.kube; \
      echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc; \
      echo 'alias k=kubectl' >> ~vagrant/.bashrc; \
      echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc; \
      \""
  done

  msg "Updating Flannel DaemonSet for Vagrant"
  # This needs to be done on a master node, just pick one from the list
  # (Workaround for OLCNE-1079)
  node=$(echo ${MASTERS} | sed -e 's/.* //')
  echo_do ssh vagrant@${node} "\"\
    kubectl --namespace kube-system get ds/kube-flannel-ds -o yaml > /tmp/kube-flannel-ds.yaml;\
    kubectl delete -f /tmp/kube-flannel-ds.yaml;\
    sed -i 's/\(- --kube-subnet-mgr\)/\1\n        - --iface=eth1/' /tmp/kube-flannel-ds.yaml;\
    sleep 60;\
    kubectl apply -f /tmp/kube-flannel-ds.yaml;\
    rm /tmp/kube-flannel-ds.yaml;\
    \""

  msg "Starting kubectl proxy service on master nodes"
  for node in ${MASTERS}; do
    echo_do ssh ${node} systemctl start kubectl-proxy.service
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
  node=$(echo ${MASTERS} | sed -e 's/.* //')
  ssh vagrant@${node} kubectl get nodes
}

#######################################
# Main
#######################################
main () {
  parse_args "$@"
  setup_networking
  setup_repos
  requirements
  install_packages
  passwordless_ssh
  msg "Oracle Linux base software installation complete."
  # All nodes are up, orchestrate installation
  if [[ -n "${OPERATOR}" ]]; then
    certificates
    bootstrap_olcne
    deploy_kubernetes
    fixups
    ready
  fi
}

main "$@"

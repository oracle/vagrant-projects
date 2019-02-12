#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2018
# Author: philippe.vanhaesendonck@oracle.com
# Description: Installs Docker Engine and setup Kubernetes cluster
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile provisions one master and n worker nodes (2 by default)
# VMs communicate via a private network:
#   - Master  : 192.168.99.100
#   - Worker i: 192.168.99.(100+i)
#
# Unless you have a paswordless local registry (see below) the provisioning
# script only pre-loads k8s and satisfies pre-requisites.
# When the VMs are provisioned run (as root):
#    on master:
#        /vagrant/scripts/kubeadm-setup-master.sh
#        (You will be prompted for your userid/password for
#        container-registry.oracle.com)
#    on each worker:
#    	/vagrant/scripts/kubeadm-setup-worker.sh
#        (You will be prompted for your userid/password for
#        container-registry.oracle.com)
#
# Optional plugins:
#     vagrant-hosts (maintains /etc/hosts for the VMs)
#     vagrant-env (use .env files for configuration)
#     vagrant-proxyconf (if you don't have direct access to the Internet)
#         see https://github.com/tmatilai/vagrant-proxyconf for configuration
#

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Define constants
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Use vagrant-env plugin if available
  if Vagrant.has_plugin?("vagrant-env")
    config.env.load('.env.local', '.env') # enable the plugin
  end

  # Number of worker nodes to provision
  NB_WORKERS = default_i('NB_WORKERS', 2)
  # Use the "Preview" channel for both Docker Engine and Kubernetes
  USE_PREVIEW = default_b('USE_PREVIEW', false)
  # Use the "Developer" channel for both Docker Engine and Kubernetes
  USE_DEV = default_b('USE_DEV', false)
  # To manage your cluster from the vagrant host, set the following variable
  # to true
  MANAGE_FROM_HOST = default_b('MANAGE_FROM_HOST', false)
  # The following will bind the manager default kubernetes proxy port (8001) to
  # the vagrant host
  BIND_PROXY = default_b('BIND_PROXY', true)
  # Memory for the VMs (2GB)
  MEMORY = default_i('MEMORY', 2048)

  # Local Registry configuration -- Use the following parameters if you have
  # configured a Local Registry
  # Repository and prefix - e.g. for local-registry.example.com:5000/kubernetes:
  # KUBE_REPO = "local-registry.example.com:5000"
  # KUBE_PREFIX = "/kubernetes"
  KUBE_REPO = default_s('KUBE_REPO', '')
  KUBE_PREFIX = default_s('KUBE_PREFIX', '')
  # Does the registry requires login? If no login is required, the provisioning
  # script will be able to run kubadm-setup on all nodes!
  KUBE_LOGIN = default_b('KUBE_LOGIN', true)
  # Does the registry use SSL?
  KUBE_SSL = default_b('KUBE_SSL', true)

end

# Convenience methods
def default_s(key, default)
  ENV[key] && ! ENV[key].empty? ? ENV[key] : default
end

def default_i(key, default)
  default_s(key, default).to_i
end

def default_b(key, default)
  default_s(key, default).to_s.downcase == 'true'
end

def setup_local_repo (node, vm)
  unless KUBE_REPO.empty? && KUBE_PREFIX.empty?
    registry = (KUBE_REPO.empty? ? 'container-registry.oracle.com' : KUBE_REPO) + 
               (KUBE_PREFIX.empty? ? '/kubernetes' : KUBE_PREFIX)
    vm.provision :shell, inline: <<-SHELL
	echo 'export KUBE_REPO_PREFIX="#{registry}"' >> ~/.bashrc
	echo 'export KUBE_REPO_PREFIX="#{registry}"' >> ~vagrant/.bashrc
    SHELL
    unless KUBE_LOGIN
      # If registry login is not required, we can run kubeadm
      vm.provision "shell",
        path: "scripts/kubeadm-setup-#{node}.sh",
        args: ["--no-login"],
        env: {"KUBE_REPO_PREFIX" => "#{registry}"}
    end
  end
end

def ensure_scheme(url)
  (url =~ /.*:\/\// ? '' : 'http://') + url
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # We start from the latest OL 7 Box
  config.vm.box = "ol7-latest"
  config.vm.box_url = "https://yum.oracle.com/boxes/oraclelinux/latest/ol7-latest.box"

  # If we use the vagrant-proxyconf plugin, we should not proxy k8s/local IPs
  # Unfortunately we can't use CIDR with no_proxy, so we have to enumerate and
  # 'blacklist' *all* IPs
  if Vagrant.has_plugin?("vagrant-proxyconf")
    ["http_proxy", "HTTP_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        puts "HTTP proxy: " + proxy
        config.proxy.http = ensure_scheme(proxy)
        break
      end
    end

    ["https_proxy", "HTTPS_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        puts "HTTPS proxy: " + proxy
        config.proxy.https = ensure_scheme(proxy)
        break
      end
    end

    no_proxy = ''
    ["no_proxy", "NO_PROXY"].each do |proxy_var|
      if ENV[proxy_var]
        no_proxy = ENV[proxy_var]
        puts "No proxy: " + no_proxy
        no_proxy += ','
        break
      end
    end
    config.proxy.no_proxy = no_proxy + "localhost,.vagrant.vm," + (".0"..".255").to_a.join(",")
  end

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider "virtualbox" do |vb|
    vb.memory = MEMORY
  end

  # Define VMs:
  # - Manager
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = "master.vagrant.vm"
    master.vm.network "private_network", ip: "192.168.99.100"
    if Vagrant.has_plugin?("vagrant-hosts")
      master.vm.provision :hosts, :sync_hosts => true
    end
    if MANAGE_FROM_HOST
      # Bind kubernetes admin port so we can administrate from host
      master.vm.network "forwarded_port", guest: 6443, host: 6443
    end
    if BIND_PROXY
      # Bind kubernetes default proxy port
      master.vm.network "forwarded_port", guest: 8001, host: 8001
    end
    # kubeadm will use the first network interface, which is the NAT interface
    # on VirtualBox and is not routable -- See OraBug 26540925
    master.vm.provision :shell, inline: <<-SHELL
      # Config file format changed in 1.12
      # Doing substitutions blindly as only the right ones will match
      # Pre 1.12 release
      sed -i 's/kubeadm init \\([-$]\\)/kubeadm init --apiserver-advertise-address=192.168.99.100 \\1/' /usr/bin/kubeadm-setup.sh
      sed -i 's/"--kube-subnet-mgr"/"--kube-subnet-mgr", "--iface=eth1"/' /usr/local/share/kubeadm/flannel-ol.yaml
      # 1.12 release
      sed -i 's/\\(bindPort: 6443\\)/\\1\\n  advertiseAddress: 192.168.99.100/' /usr/bin/kubeadm-setup.sh
      sed -i 's/\\(- --kube-subnet-mgr\\)/\\1\\n        - --iface=eth1/' /usr/local/share/kubeadm/flannel-ol.yaml
    SHELL
    if MANAGE_FROM_HOST
      # Add localhost to the list of allowed clients
      master.vm.provision :shell, inline: <<-SHELL
        sed -i 's/kubeadm init \\([-$]\\)/kubeadm init --apiserver-cert-extra-sans=localhost,localhost.localdomain,127.0.0.1 \\1/' /usr/bin/kubeadm-setup.sh
      SHELL
    end
    if BIND_PROXY
      # Bind on all interfaces and accept connections from any hosts
      master.vm.provision :shell, inline: <<-SHELL
	sed -i 's/"KUBECTL_PROXY_ARGS=.*"/"KUBECTL_PROXY_ARGS=--port 8001 --accept-hosts='.*' --address=0.0.0.0"/' /etc/systemd/system/kubectl-proxy.service.d/10-kubectl-proxy.conf
	systemctl daemon-reload
      SHELL
    end
    setup_local_repo("master", master.vm)
  end
  # - Workers
  (1..NB_WORKERS).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.hostname = "worker#{i}.vagrant.vm"
      ip = 100 + i
      worker.vm.network "private_network", ip: "192.168.99.#{ip}"
      if Vagrant.has_plugin?("vagrant-hosts")
        worker.vm.provision :hosts, :sync_hosts => true
      end
      setup_local_repo("worker", worker.vm)
    end
  end

  # Provisioning: install Docker and Kubernetes
  args = []
  args.push("--preview") if USE_PREVIEW
  args.push("--dev") if USE_DEV
  args.push("--insecure", KUBE_REPO) unless KUBE_SSL
  config.vm.provision "shell",
    path: "scripts/provision.sh",
    args: args
end

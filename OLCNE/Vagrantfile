#
# Vagrantfile for Oracle Linux Cloud Native Environment
#
# Copyright (c) 2019, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Description: Deploys an Oracle Linux Cloud Native Environment
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile creates an Oracle Linux Cloud Native Environment and
# deploys the Kubernetes module to the master and worker nodes.
# VMs communicate via a private network:
#   - Operator: 192.168.99.100         (Optional, none by default)
#   - Master i: 192.168.99.(100+i)     (1 by default, 3 in HA mode)
#   - Worker i: 192.168.99.(110+i)     (2 by default)
#
# Optional plugins:
#     vagrant-hosts (maintains /etc/hosts for the VMs)
#     vagrant-env (use .env files for configuration)
#     vagrant-proxyconf (if you don't have direct access to the Internet)
#         see https://github.com/tmatilai/vagrant-proxyconf for configuration
#

# Required for the Disks feature
Vagrant.require_version ">= 2.2.8"
ENV['VAGRANT_EXPERIMENTAL'] = 'disks'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# Box metadata location and box name
BOX_URL = "https://oracle.github.io/vagrant-projects/boxes"
BOX_NAME = "oraclelinux/8"

# Define constants
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Use vagrant-env plugin if available
  if Vagrant.has_plugin?("vagrant-env")
    config.env.load(".env.local", ".env") # enable the plugin
  end

  # vCPUS (2) and Memory for the VMs (3GB)
  CPUS = default_i('CPUS', 2)
  MEMORY = default_i("MEMORY", 3072)

  # Group VirtualBox containers
  VB_GROUP = default_s("VB_GROUP", "OLCNE")

  # Multi-master setup. Deploy 3 masters in HA mode.
  MULTI_MASTER = default_b('MULTI_MASTER', false)

  # Separate operator node for the Oracle Linux Cloud Native Environment
  # Platform API Server and Platform Agent (default is to install the
  # components on the (first) master node
  #
  # If multi-master is enabled, the standalone operator is automatically
  # enabled for routing purposes
  if MULTI_MASTER
    STANDALONE_OPERATOR = true
  else
    STANDALONE_OPERATOR = default_b('STANDALONE_OPERATOR', false)
  end

  # Creates and extra disk (/dev/sdb) so it can be used as a
  # Gluster Storage for Kubernetes Persistent Volumes
  EXTRA_DISK = default_b('EXTRA_DISK', false)

  # Override number of masters to deploy
  # This should not be changed -- for development purpose
  NB_MASTERS = default_i('NB_MASTERS', MULTI_MASTER ? 3 : 1)

  # Number of worker nodes to provision
  NB_WORKERS = default_i('NB_WORKERS', 2)

  # Bind the kubectl proxy from the (first) master to the vagrant host
  BIND_PROXY = default_b('BIND_PROXY', false)

  # Additional yum channel to consider (e.g. local repo)
  YUM_REPO = default_s('YUM_REPO', '')

  # Add Oracle Linux Cloud Native Environment developer channel
  OLCNE_DEV = default_b('OLCNE_DEV', false)

  # Set the default OLCNE_ENV_NAME and OLCNE_CLUSTER_NAMEs
  OLCNE_ENV_NAME = default_s('OLCNE_ENV_NAME', 'olcne-env')
  OLCNE_CLUSTER_NAME = default_s('OLCNE_CLUSTER_NAME', 'olcne-cluster')

  # Container registry for Oracle Linux Cloud Native Environment images
  # You can use registry mirrors in a region close to you.
  # Check the README.md file for more details.
  REGISTRY_OLCNE = default_s('REGISTRY_OLCNE', 'container-registry.oracle.com/olcne')

  # Deploy Istio?
  DEPLOY_ISTIO = default_b('DEPLOY_ISTIO', false)

  # Helm is required to deploy Istio otherwise it's optional
  if DEPLOY_ISTIO
    DEPLOY_HELM = true
  else
    DEPLOY_HELM = default_b('DEPLOY_HELM', false)
  end

  HELM_MODULE_NAME = default_s('HELM_MODULE_NAME', 'olcne-helm')
  ISTIO_MODULE_NAME = default_s('ISTIO_MODULE_NAME', 'olcne-istio')

  # Use specific component version (mainly used for development)
  NGINX_IMAGE = default_s('NGINX_IMAGE', 'nginx:1.17.7')

  # Verbose console
  VERBOSE = default_b('VERBOSE', false)
end

# Convenience methods
def default_s(key, default)
  ENV[key] && ! ENV[key].empty? ? ENV[key] : default
end

def default_i(key, default)
  default_s(key, default).to_i
end

def default_b(key, default)
  default_s(key, default).to_s.downcase == "true"
end

def ensure_scheme(url)
  (url =~ /.*:\/\// ? "" : "http://") + url
end

def provision_vm(vm, vm_args)
  args = vm_args.clone
  args.push("--olcne-environment-name", OLCNE_ENV_NAME)
  args.push("--olcne-cluster-name", OLCNE_CLUSTER_NAME)
  args.push("--multi-master") if MULTI_MASTER
  args.push("--repo", YUM_REPO) unless YUM_REPO == ""
  args.push("--olcne-dev") if OLCNE_DEV
  args.push("--with-helm") if DEPLOY_HELM
  args.push("--helm-module-name", HELM_MODULE_NAME) if DEPLOY_HELM
  args.push("--with-istio") if DEPLOY_ISTIO
  args.push("--istio-module-name", ISTIO_MODULE_NAME) if DEPLOY_ISTIO
  args.push("--registry-olcne", REGISTRY_OLCNE) if REGISTRY_OLCNE
  args.push("--verbose") if VERBOSE
  vm.provision "shell",
    path: "scripts/provision.sh",
    args: args
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = BOX_NAME
  config.vm.box_url = "#{BOX_URL}/#{BOX_NAME}.json"

  # If we use the vagrant-proxyconf plugin, we should not proxy k8s/local IPs
  # Unfortunately we can't use CIDR with no_proxy, so we have to enumerate and
  # 'blacklist' *all* IPs
  if Vagrant.has_plugin?("vagrant-proxyconf")
    has_proxy = false
    ["http_proxy", "HTTP_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        puts "HTTP proxy: " + proxy
        config.proxy.http = ensure_scheme(proxy)
        has_proxy = true
        break
      end
    end

    ["https_proxy", "HTTPS_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        puts "HTTPS proxy: " + proxy
        config.proxy.https = ensure_scheme(proxy)
        has_proxy = true
        break
      end
    end

    if has_proxy
      # Only consider no_proxy if we have proxies defined.
      no_proxy = ""
      ["no_proxy", "NO_PROXY"].each do |proxy_var|
        if ENV[proxy_var]
          no_proxy = ENV[proxy_var]
          puts "No proxy: " + no_proxy
          no_proxy += ","
          break
        end
      end
      config.proxy.no_proxy = no_proxy + "localhost,.vagrant.vm," + (".0"..".255").to_a.join(",")
    end
  end

  # Provider-specific configuration -- VirtualBox
  config.vm.provider "virtualbox" do |vb, override|
    vb.memory = MEMORY
    vb.cpus = CPUS
    vb.customize ["modifyvm", :id, "--groups", "/" + VB_GROUP]
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    if EXTRA_DISK
      override.vm.disk :disk, size: '16GB', name: 'extra_disk'
    end
  end
  config.vm.provider :libvirt do |lv|
    lv.memory = MEMORY
    lv.cpus = CPUS
    lv.nested = true
    if EXTRA_DISK
      lv.storage :file, :size => '16G', :type => 'qcow2'
    end
  end

  # Workers provisioning
  workers = ""
  (1..NB_WORKERS).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.hostname = "worker#{i}.vagrant.vm"
      ip = 110 + i
      ip_addr = "192.168.99.#{ip}"
      workers += "#{ip_addr},"
      worker.vm.network "private_network", ip: ip_addr
      if Vagrant.has_plugin?("vagrant-hosts")
        worker.vm.provision :hosts, :sync_hosts => true, :add_localhost_hostnames => false
      end
      # Provisioning: install stuff
      provision_vm(worker.vm, ["--worker"])
    end
  end

  # Masters provisioning
  masters = ""
  NB_MASTERS.downto(1) do |i|
    config.vm.define "master#{i}" do |master|
      master.vm.hostname = "master#{i}.vagrant.vm"
      ip = 100 + i
      ip_addr = "192.168.99.#{ip}"
      masters += "#{ip_addr},"
      master.vm.network "private_network", ip: ip_addr
      if Vagrant.has_plugin?("vagrant-hosts")
        master.vm.provision :hosts, :sync_hosts => true, :add_localhost_hostnames => false
      end
      if BIND_PROXY && i == 1
        # Bind kubectl proxy proxy port
        master.vm.network "forwarded_port", guest: 8001, host: 8001
      end
      # Provisioning: install stuff
      args = ["--master", "--nginx-image", NGINX_IMAGE]
      if !STANDALONE_OPERATOR && i == 1
        args.push("--operator")
        args.push("--workers", workers.chop)
        args.push("--masters", masters.chop)
      end
      provision_vm(master.vm, args)
    end
  end

  # Operator node, if standalone
  if STANDALONE_OPERATOR
    config.vm.define "operator" do |operator|
      operator.vm.hostname = "operator.vagrant.vm"
      operator.vm.network "private_network", ip: "192.168.99.100"
      if Vagrant.has_plugin?("vagrant-hosts")
        operator.vm.provision :hosts, :sync_hosts => true, :add_localhost_hostnames => false
      end
      args = ["--operator"]
      args.push("--workers", workers.chop)
      args.push("--masters", masters.chop)
      args.push("--nginx-image", NGINX_IMAGE)
      provision_vm(operator.vm, args)
    end
  end
end

#
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Linux virtual machine.
# Optional plugins:
#     vagrant-env (use .env files for configuration)
#     vagrant-proxyconf (if you don't have direct access to the Internet)
#         see https://github.com/tmatilai/vagrant-proxyconf for configuration
#     vagrant-reload (allow VM reload during provisioning)
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Box metadata location and box name
BOX_URL = "https://oracle.github.io/vagrant-projects/boxes"
BOX_NAME = "oraclelinux/8"

# define hostname
NAME = "ol8-vagrant"

# UI object for printing information
ui = Vagrant::UI::Prefixed.new(Vagrant::UI::Colored.new, "vagrant")

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = BOX_NAME
  config.vm.box_url = "#{BOX_URL}/#{BOX_NAME}.json"
  config.vm.define NAME

  if Vagrant.has_plugin?("vagrant-env")
    ui.info "Loading environment from .env files"
    config.env.load(".env.local", ".env")
  end

  # change memory size
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.name = NAME
  end
  config.vm.provider :libvirt do |v|
    v.memory = 2048
  end

  # add proxy configuration from host env - optional
  if Vagrant.has_plugin?("vagrant-proxyconf")
    ui.info "Getting Proxy Configuration from Host..."
    has_proxy = false
    ["http_proxy", "HTTP_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        ui.info "HTTP proxy: " + proxy
        config.proxy.http = proxy
        has_proxy = true
        break
      end
    end

    ["https_proxy", "HTTPS_PROXY"].each do |proxy_var|
      if proxy = ENV[proxy_var]
        ui.info "HTTPS proxy: " + proxy
        config.proxy.https = proxy
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
          ui.info "No proxy: " + no_proxy
          no_proxy += ","
          break
        end
      end
      config.proxy.no_proxy = no_proxy + "localhost,.vagrant.vm"
    end
  else
    ["http_proxy", "HTTP_PROXY", "https_proxy", "HTTPS_PROXY"].each do |proxy_var|
      if ENV[proxy_var]
        ui.warn 'To enable proxies in your VM, install the vagrant-proxyconf plugin'
        break
      end
    end
  end

  # VM hostname
  config.vm.hostname = NAME

  # Oracle port forwarding
  # config.vm.network "forwarded_port", guest: 22, host: 2220

  # Provision everything on the first run
  config.vm.provision "shell", path: "scripts/install.sh"
  if Vagrant.has_plugin?("vagrant-reload")
    config.vm.provision "shell", inline: "echo 'Reloading your VM to activate the latest kernel'"
    config.vm.provision :reload
  else
    config.vm.provision "shell", inline: "echo 'You need to reload your VM to activate the latest kernel'"
  end

  # Extend provisioning
  if ENV['EXTEND']
    ENV['EXTEND'].sub(/^[ ,]+/,'').split(/[ ,]+/).each do |extension|
      found = false
      ["scripts", "scripts.local"].each do |script_dir|
        script = "#{script_dir}/#{extension}.sh"
        if File.file?(script)
          ui.info "Extension #{extension} using #{script} enabled"
          found = true
          config.vm.provision "shell", inline: "echo 'Running provisioner for extension #{extension}'"
          config.vm.provision "shell",
            path: script,
            env: ENV.select { |key, value| key.to_s.match(/^#{extension.upcase.gsub('-','_')}_/) }
          break
        end
      end
      unless found
        ui.error "Extension #{extension} does not exist -- ignored"
      end
    end
  end

  # Expose ports to the host
  if ENV['EXPOSE']
    ENV['EXPOSE'].sub(/^[ ,]+/,'').split(/[ ,]+/).each do |expose|
      host_port, guest_port = expose.split(':')
      ui.info "Guest port #{guest_port} exposed to port #{host_port} on host"
      config.vm.network "forwarded_port", guest: guest_port, host: host_port
    end
  end

  config.vm.provision "shell", inline: "echo 'INSTALLER: Installation complete, Oracle Linux 8 ready to use!'"

end

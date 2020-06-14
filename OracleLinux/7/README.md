# ol7-vagrant

A vagrant box that provisions Oracle Linux automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

## Prerequisites

1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://vagrantup.com/)

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
1. cd vagrant-boxes/OracleLinux/7
1. Run `vagrant status` to check Vagrantfile status and possible plugin(s) required
1. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection!
   1. The Vagrant file allows for customization.
1. SSH into the VM either by using `vagrant ssh`
   If required, by Vagrantfile you can also setup ssh port forwarding.
1. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Optional plugins

When installed, this Vagrantfile will make use of the following third party Vagrant plugins:

- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access the Internet through proxy. See
plugin documentation for the configuration.
- [vagrant-reload](https://github.com/aidanns/vagrant-reload): reload the VM
during provisioning to activate the latest kernel.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Other info

- If you need to, you can connect to the machine via `vagrant ssh`.
- On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.

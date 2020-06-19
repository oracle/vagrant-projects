# ol6-vagrant

A Vagrant project that provisions Oracle Linux automatically, using Vagrant, an Oracle Linux 6 box and a shell script.

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. cd vagrant-projects/OracleLinux/6
3. Run `vagrant status` to check Vagrantfile status and possible plugin(s) required
4. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection!
   2. The Vagrant file allows for customization.
5. SSH into the VM either by using `vagrant ssh`
   If required, by Vagrantfile you can also setup ssh port forwarding.
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

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

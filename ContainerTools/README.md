# Vagrantfile to set up Oracle Linux 8 with Container Tools
A Vagrantfile that installs and configures the Container Tools module on Oracle Linux 8.

This module provides the tools to use container runtimes. That is: mainly Podman, but also Buildah, Skopeo...

__Note:__ This Vagrant project is deprecated. However, the same functionality is
available as an extension to the OracleLinux/8 project. For more information,
see the [Container Tools](../OracleLinux/8/README.md#container-tools) section of
the OracleLinux/8 [README.md](../OracleLinux/8/README.md) file.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
1. Change into the `vagrant-boxes/ContainerTools` folder
1. Run `vagrant up; vagrant ssh`
1. Within the guest, run Podman commands, for example `podman run -it oraclelinux:7-slim` to run an Oracle Linux 7 container, or `podman run -ti oraclelinux:8-slim` to run an Oracle Linux 8 container

## Optional plugins
When installed, this Vagrantfile will make use of the following third party Vagrant plugin:
- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access the Internet through proxy. See
plugin documentation for the configuration.

To intall Vagrant plugins run:
```
vagrant plugin install <name>...
```

## Feedback
Please provide feedback of any kind via Github issues on this repository.

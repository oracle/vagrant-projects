# Vagrant project to set up Oracle Linux 7 with Docker engine

A Vagrantfile that installs and configures Docker engine on Oracle Linux 7 with Btrfs as storage

__Note:__ This Vagrant project is deprecated. However, the same functionality is
available as an extension to the OracleLinux/7 project. For more information,
see the [Oracle Container Runtime for Docker](../OracleLinux/7/README.md#oracle-container-runtime-for-docker)
section of the OracleLinux/7 [README.md](../OracleLinux/7/README.md) file.

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the `vagrant-projects/DockerEngine` directory
3. Run `vagrant up; vagrant ssh`
4. Within the guest, run Docker commands, for example `docker run -it oraclelinux:7-slim` to run an Oracle Linux 7 container, or `docker run -ti oraclelinux:8-slim` to run an Oracle Linux 8 container

## Optional plugins

When installed, this Vagrantfile will make use of the following third party Vagrant plugin:

- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access the Internet through proxy. See
plugin documentation for the configuration.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Feedback

Please provide feedback of any kind via Github issues on this repository.

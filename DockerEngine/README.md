# Vagrantfile to set up Oracle Linux 7 with Docker engine
A Vagrantfile that installs and configures Docker engine on Oracle Linux 7 with Btrfs as storage

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
2. Change into the `vagrant-boxes/DockerEngine` folder
3. Run `vagrant up; vagrant ssh`
4. Within the guest, run Docker commands, for example `docker run -it oraclelinux:6-slim` to run an Oracle Linux 6 container, or `docker run -ti oraclelinux:7-slim` to run an Oracle Linux 7 container

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

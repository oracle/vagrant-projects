# ol7-vagrant

A Vagrant project to automatically build an Oracle Linux 7 virtual machine using either VirtualBox or libvirtd with optional extras including a LAMP stack or container runtime.

## Prerequisites

Read the [prerequisites in the top level README](../../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
1. Change into the `vagrant-projects/OracleLinux/7` directory
1. Run `vagrant status` to check Vagrantfile status and possible plugin(s) required
1. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection!
   1. The Vagrant file allows for customization.
1. SSH into the VM either by using `vagrant ssh`
   If required, by Vagrantfile you can also setup ssh port forwarding.
1. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Optional plugins

When installed, this Vagrant project will make use of the following third party Vagrant plugins:

- [vagrant-env](https://github.com/gosuri/vagrant-env): loads environment
variables from .env files;
- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access the Internet through proxy. See
plugin documentation for the configuration.
- [vagrant-reload](https://github.com/aidanns/vagrant-reload): reload the VM
during provisioning to activate the latest kernel.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Extending the project

This project can easily be extended by running additional scripts during provisioning and optionally expose guest ports on the host.

Environment variables are used to pass the parameters to the Vagrantfile:

- `EXTEND`: comma separated list of extensions.  
   For each specified extension a script named `<extension>.sh` is automatically run during provisioning.  
   Scripts must be located in the `scripts` or `scripts.local` directory.
- `EXPOSE`: comma separated list of ports to expose in the format: `<host port>:<guest port>`

Example: to extend the project with the `lamp` extension and expose the guest port 80 to 8080 on the host:

- On a Linux or macOS host:  
   `EXTEND=lamp EXPOSE=8080:80 vagrant up`
- On a Windows host:  
   `set EXTEND=lamp && set EXPOSE=8080:80 && vagrant up`

Alternatively, if the `vagrant-env` plugin is installed variables can be defined in the `.env` or `.env.local` files.

Additionally, you can pass parameters to extensions using environment variables having a name starting with the extension name in uppercase followed by an underscore. E.g., for a Linux host:

```shell
EXTEND=my-extension MY_EXTENSION_PARAM=1234 vagrant up
```

## Sample extensions

### LAMP stack

Provisions an Oracle Linux LAMP (**L**inux, **A**pache, **M**ySQL, **P**HP) stack.

Set in your environment:

```shell
EXTEND=lamp
EXPOSE=8080:80
```

Guest port "80" (Apache) is redirected to Host port "8080".  
Once ready, you can test it by opening following URL on your Host OS: http://localhost:8080/info.php

### Oracle Container Runtime for Docker

Installs and configures [Oracle Container Runtime for Docker](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/) using Btrfs as storage.

Set in your environment:

```shell
EXTEND=container-runtime
```

Within the guest, run Docker commands, for example `docker run -it oraclelinux:7-slim` to run an Oracle Linux 7 container, or `docker run -ti oraclelinux:8-slim` to run an Oracle Linux 8 container

## Other info

- If you need to, you can connect to the machine via `vagrant ssh`.
- The directory in which the `Vagrantfile` is located is automatically mounted into the guest at `/vagrant` as a shared folder.

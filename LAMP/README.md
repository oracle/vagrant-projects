# ol7-lamp

A Vagrant project that provisions Oracle Linux LAMP solution automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

__Note:__ This Vagrant project is deprecated. However, the same functionality is
available as an extension to the OracleLinux/7 project. For more information,
see the [LAMP stack](../OracleLinux/7/README.md#lamp-stack) section of the
OracleLinux/7 [README.md](../OracleLinux/7/README.md) file.

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. cd vagrant-projects/LAMP
3. Run `vagrant status` to check Vagrantfile status and possible plugin(s) required
4. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection!
   2. The Vagrant file allows for customization.
5. SSH into the VM either by using `vagrant ssh`
   If required, by Vagrantfile you can also setup ssh port forwarding.
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.
7. Guest port "80" (Apache) is redirected to Host port "8080"
   Once ready, you can test it by opening following URL on your Host OS: `http://localhost:8080/info.php`.

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

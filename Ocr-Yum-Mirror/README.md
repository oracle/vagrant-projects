# ocr-yum-mirror

A Vagrant project to automatically build an Oracle Linux Yum Server mirror and, at the same time, an Oracle Container Registry mirror for Oracle Cloud Native Environment.
This projects collects all the software (RPMs and container images) required to deploy/install Oracle Cloud Native Environment on Oracle Linux 8 and can be very helpful while looking for an offline deployment option for the same.
 By default, following yum channels are mirrored on the vagrant machine:

- ol8_baseos_latest
- ol8_appstream
- ol8_olcne15
- ol8_addons
- ol8_UEKR6
- ol8_UEKR7

Optionally further channels can be added once the virtual machine completed the first boot.
Channles could also be added to the script `/home/vagrant/sync-yum.sh` to the new channels will be synced automatically.

## Prerequisites

Read the [prerequisites in the top level README](../../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
1. Change into the `vagrant-projects/ocr-yum-mirror` directory
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

## Further information

The vagrant box contains two custom scripts to possibly resync the Yum as well as the OCR (Oracle Container Registry) mirrors.
Those commands could be edited to add further yum-channels to be mirrored or customize the synchronization process.
Examples:

- Synchronize Yum mirror - to be executed with "vagrant" user

```shell
/home/vagrant/sync-yum.sh
```

- Synchronize OCR mirror - to be executed with "vagrant" user

```shell
/home/vagrant/sync-ocr.sh
```

## Other info

- If you need to, you can connect to the machine via `vagrant ssh`.
- The directory in which the `Vagrantfile` is located is automatically mounted into the guest at `/vagrant` as a shared folder.

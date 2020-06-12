# vagrant-projects

A collection of Vagrant projects that provision Oracle and other software automatically, using Vagrant, an Oracle Linux box, and shell scripts. Unless indicated otherwise, these projects work with both Oracle VM VirtualBox and libvirt/KVM.

## Prerequisites

All projects in this repository require Vagrant and either Oracle VM VirtualBox or libvirt/KVM with the vagrant-libvirt plugin.

### If using VirtualBox

1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

### If using libvirt/KVM on Oracle Linux

1. Read [Philippe's blog post](https://blogs.oracle.com/linux/getting-started-with-the-vagrant-libvirt-provider-for-oracle-linux) for instructions on using the Vagrant libvirt provider

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the desired project folder
3. Follow the README.md instructions inside the folder

## Know issues

### Metadata not found when creating new VM

We have recently renamed this repository. Unfortunately the new URL for the boxes metadata will not be taken into consideration if you already have a box locally (See [Vagrant issue #9637](https://github.com/hashicorp/vagrant/issues/9637)).

You will see the following when you create a new VM:

```
==> ol7-vagrant: Checking if box 'oraclelinux/7' version '7.8.103' is up to date...
==> ol7-vagrant: There was a problem while downloading the metadata for your box
==> ol7-vagrant: to check for updates. This is not an error, since it is usually due
==> ol7-vagrant: to temporary network problems. This is just a warning. The problem
==> ol7-vagrant: encountered was:
==> ol7-vagrant:
==> ol7-vagrant: The requested URL returned error: 404 Not Found
```

When this happens:

1. Ensure you have the correct metadata URL in your Vagrantfile:  
   `BOX_URL = "https://oracle.github.io/vagrant-projects/boxes"`
1. Remove your local copy of the box -- E.g. for oraclelinux/7:  
   `vagrant box remove --all oraclelinux/7`

## Feedback

Please provide feedback of any kind via Github issues on this repository.

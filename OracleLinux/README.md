# ol7-vagrant
A vagrant box that provisions Oracle Linux automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/gvenzl/vagrant-boxes`
2. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection!
   2. The Vagrant file allows for customization, if desired (see [Customization](#customization))
3. SSH into the VM either by using `vagrant ssh` or `ssh -p 2220 root@localhost`.
6. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Other info

* If you need to, you can connect to the machine via `vagrant ssh`.
* The ssh port 22 is forwarded to 2220 in the outside world.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.

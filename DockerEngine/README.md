# Vagrantfile to set up Oracle Linux 7 with Docker engine
A Vagrantfile that installs and configures Docker engine on Oracle Linux 7 with Btrfs as storage 

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
2. Change into the DockerEngine folder
3. Run `vagrant up; vagrant ssh`
4. Within the guest, run Docker commands, for example `sudo docker run -it oraclelinux:6-slim`

## Feedback
Please provide feedback of any kind via Github issues on this repository.

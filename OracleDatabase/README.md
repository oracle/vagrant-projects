# Oracle Database Vagrant boxes
This directory contains Vagrant build files to provision an Oracle Database automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
2. Change into the desired version folder
3. Download the installation zip files from OTN into this folder - first time only:
[http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
4. Run `vagrant up`
5. Connect to the database.
6. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

**For more information please check the individual README within each folder!**

## Acknowledgements
Based on:
@steveswinsburg's work here: https://github.com/steveswinsburg/oracle12c-vagrant  
@totalamateurhour's work here: https://github.com/totalamateurhour/oracle-12.2-vagrant  
@gvenzl's work here: https://github.com/gvenzl/vagrant-boxes

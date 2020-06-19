# Oracle Database Vagrant projects

This directory contains Vagrant build files to provision an Oracle Database automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM.

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the desired version directory
3. Download the installation zip file(s) from OTN into this directory - first time only:
[http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
4. Run `vagrant up`
5. Connect to the database.
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

**For more information please check the individual README within each directory!**

## Acknowledgements

Based on:  
@steveswinsburg's work here: [https://github.com/steveswinsburg/oracle12c-vagrant](https://github.com/steveswinsburg/oracle12c-vagrant)  
@totalamateurhour's work here: [https://github.com/totalamateurhour/oracle-12.2-vagrant](https://github.com/totalamateurhour/oracle-12.2-vagrant)  
@gvenzl's work here: [https://github.com/gvenzl/vagrant-boxes](https://github.com/gvenzl/vagrant-boxes)

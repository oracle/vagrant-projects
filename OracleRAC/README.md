# Oracle Real Application Cluster (RAC) Vagrant project on VirtualBox or KVM/libVirt provider

###### Author: Ruggero Citton (<ruggero.citton@oracle.com>) - Orale RAC Pack, Cloud Innovation and Solution Engineering Team

This directory contains Vagrant build files to provision automatically
two Oracle RAC nodes (12.2, 18c, 19c), using Vagrant, Oracle Linux 7 and shell scripts.
![](images/OracleRAC.png)

## Prerequisites

1. Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM
1. You need to download Database binary separately

## Free disk space requirement

- Grid Infrastructure and Database binary zip under "./ORCL_software": ~9.3 Gb
- Grid Infrastructure and Database binary on u01 vdisk (node1/node2): ~20 Gb
- OS guest vdisk (node1/node2): ~2 Gb
  - In case of KVM/libVirt provider, the disk is created under `storage pool = "storage_pool_name"`
  - In case of VirtualBox
    - Use `VBoxManage list systemproperties |grep folder` to find out the current VM default location
    - Use `VBoxManage setproperty machinefolder <your path>` to set VM default location
- ASM shared virtual disks (fixed size): ~80 Gb

## Memory requirement

Running two nodes RAC at least 6Gb per node are required
Using Oracle Restart, only one node it's active

## VirtualBox host-Only

The guest VMs are using an "host-Only" network defined as 'vboxnet0'

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects.git`
2. Change into OracleRAC folder (`/repo clone path/vagrant-projects/RACPack/OracleRAC`)
3. Download Grid Infrastructure and Database binary from OTN into `./ORCL_software` folder (*)
4. Run `vagrant up`
5. Connect to the database.
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

(*) Download Grid Infrastructure and Database binary from OTN into `ORCL_software` folder
https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

    Accept License Agreement
    go to version (12.2, 18c, 19c) for Linux x86-64 you need -> "See All", example

    * Oracle Database 19c Grid Infrastructure (19.3) for Linux x86-64
        LINUX.X64_193000_grid_home.zip (3,059,705,302 bytes)
        (sha256sum - d668002664d9399cf61eb03c0d1e3687121fc890b1ddd50b35dcbe13c5307d2e)

    * Oracle Database 19c (19.3) for Linux x86-64
       LINUX.X64_193000_db_home.zip (4,564,649,047 bytes)
       (sha256sum - ba8329c757133da313ed3b6d7f86c5ac42cd9970a28bf2e6233f3235233aa8d8)

## Customization

You can customize your Oracle environment by amending the parameters in the configuration file: `./config/vagrant.yml`
The following can be customized:

#### node1/node2

- `vm_name`:    VM Guest partial name. The full name will be <prefix_name>-<vm_name>
- `mem_size`:   VM Guest memory size Mb (minimum 6Gb --> 6144)
- `cpus`:       VM Guest virtual cores
- `public_ip`:  VM public ip. VirtualBox `vboxnet0` hostonly is in use
- `vip_ip`:     Oracle RAC VirtualIP (VIP). VirtualBox 'vboxnet0' hostonly is in use
- `private_ip`: VM private ip.
- `storage_pool_name`: KVM/libVirt storage pool name
- `u01_disk`:          VirtualBox Oracle binary virtual disk (u01) file path

#### shared network

- `prefix_name`:    VM Guest prefix name (the GI cluster name will be: <prefix_name>-c')
- `domain`  :       VM Guest domain name
- `scan_ip1`:       Oracle RAC SCAN IP1
- `scan_ip2`:       Oracle RAC SCAN IP2
- `scan_ip3`:       Oracle RAC SCAN IP3

#### shared storage

- `storage_pool_name`: KVM/libVirt Oradata dbf KVM storage pool name
- `oradata_disk_path`: VirtualBox Oradata dbf path
- `asm_disk_num`:      Oracle RAC Automatic Storage Manager virtual disk number (min 4)
- `asm_disk_size`:     Oracle RAC Automatic Storage Manager virtual disk size in Gb (at least 10)
- `p1_ratio`:          ASM disks partiton ration (%). Min 10%, Max 80%

#### environment

- `provider`:         It's defining the provider to be used: 'libvirt' or 'virtualbox'
- `grid_software`:    Oracle Database 18c Grid Infrastructure (18.3) for Linux x86-64 zip file
- `db_software`:      Oracle Database 18c (18.3) for Linux x86-64 zip file
- `root_password`:    VM Guest root password
- `grid_password`:    VM Guest grid password
- `oracle_password`:  VM Guest oracle password
- `sys_password`:     Oracled RDBMS SYS password
- `pdb_password`:     Oracled PDB SYS password
- `ora_languages`:    Oracle products languages
- `nomgmtdb`:         Oracle GI Management database creation (true/false)
- `orestart`:         Oracle GI configured as Oracle Restart (true/false)
- `db_name`:          Oracle RDBMS database name
- `pdb_name`:         Oracle RDBMS pluggable database name
- `db_type`:          Oracle RDBMS type: RAC, RACONE, SI (single Instance)
- `cdb`:              Oracle RDBMS database created as container (true/false)

#### Virtualbox provider Example:

    node1:
      vm_name: node1
      mem_size: 8192
      cpus: 2
      public_ip:  192.168.56.111
      vip_ip:     192.168.56.112
      private_ip: 192.168.200.111
      u01_disk: ./node1_u01.vdi

    node2:
      vm_name: node2
      mem_size: 8192
      cpus: 2
      public_ip:  192.168.56.121
      vip_ip:     192.168.56.122
      private_ip: 192.168.200.122
      u01_disk: ./node2_u01.vdi

    shared:
      prefix_name:   vgt-ol7-rac
      # ---------------------------------------------
      domain:   localdomain
      scan_ip1: 192.168.56.115
      scan_ip2: 192.168.56.116
      scan_ip3: 192.168.56.117
      # ---------------------------------------------
      non_rotational: 'on'
      # ---------------------------------------------
      asm_disk_path:
      asm_disk_num:   4
      asm_disk_size: 20
      p1_ratio:      80
      # ---------------------------------------------

    env:
      provider: virtualbox
      # ---------------------------------------------
      gi_software:     LINUX.X64_193000_grid_home.zip
      db_software:     LINUX.X64_193000_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      pdb_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------
      nomgmtdb:        true
      orestart:        false
      # ---------------------------------------------
      db_name:         DB193H1
      pdb_name:        PDB1
      db_type:         RAC
      cdb:             false
      # ---------------------------------------------

#### KVM/libVirt provider Example:

    node1:
      vm_name: node1
      mem_size: 8192
      cpus: 2
      public_ip:  192.168.125.111
      vip_ip:     192.168.125.112
      private_ip: 192.168.200.111
      storage_pool_name: Vagrant_KVM_Storage

    node2:
      vm_name: node2
      mem_size: 8192
      cpus: 2
      public_ip:  192.168.125.121
      vip_ip:     192.168.125.122
      private_ip: 192.168.200.122
      storage_pool_name: Vagrant_KVM_Storage

    shared:
      prefix_name:   vgt-ol7-rac
      # ---------------------------------------------
      domain:   localdomain
      scan_ip1:      192.168.125.115
      scan_ip2:      192.168.125.116
      scan_ip3:      192.168.125.117
      # ---------------------------------------------
      asm_disk_num:   4
      asm_disk_size: 20
      p1_ratio:      80
      storage_pool_name: Vagrant_KVM_Storage
      # ---------------------------------------------

    env:
      provider: libvirt
      # ---------------------------------------------
      gi_software:     LINUX.X64_193000_grid_home.zip
      db_software:     LINUX.X64_193000_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      pdb_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------
      nomgmtdb:        true
      orestart:        false
      # ---------------------------------------------
      db_name:         DB193H1
      pdb_name:        PDB1
      db_type:         RAC
      cdb:             false
      # ---------------------------------------------

## Running scripts after setup

You can have the installer run scripts after setup by putting them in the `userscripts` directory below the directory where you have this file checked out. Any shell (`.sh`) or SQL (`.sql`) scripts you put in the `userscripts` directory will be executed by the installer after the database is set up and started. Only shell and SQL scripts will be executed; all other files will be ignored. These scripts are completely optional.
Shell scripts will be executed as the root user, which has sudo privileges. SQL scripts will be executed as SYS.
To run scripts in a specific order, prefix the file names with a number, e.g., `01_shellscript.sh`, `02_tablespaces.sql`, `03_shellscript2.sh`, etc.

## Note

- `SYSTEM_TIMEZONE`: `automatically set (see below)`
  The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
- Wallet Zip file location `/tmp/wallet_<pdb name>.zip`.
  Copy the file on client machine, unzip and set TNS_ADMIN to Wallet loc. Connect to DB using Oracle Sql Client or using your App
- Using KVM/libVirt provider you may need add a firewall rule to permit NFS shared folder mounted on the guest

    example: using 'uwf' : `sudo ufw allow to 192.168.121.1` where 192.168.121.1 is the IP for the `vagrant-libvirt` network (created by vagrant automatically)

      virsh net-dumpxml vagrant-libvirt
      <network connections='1' ipv6='yes'>
        <name>vagrant-libvirt</name>
        <uuid>d2579032-4e5e-4c3f-9d42-19b6c64ac609</uuid>
        <forward mode='nat'>
          <nat>
            <port start='1024' end='65535'/>
          </nat>
        </forward>
        <bridge name='virbr1' stp='on' delay='0'/>
        <mac address='52:54:00:05:12:14'/>
        <ip address='192.168.121.1' netmask='255.255.255.0'>
          <dhcp>
            <range start='192.168.121.1' end='192.168.121.254'/>
          </dhcp>
        </ip>
      </network>
- If you are behind a proxy, set the following env variables
  - (Linux/MacOSX)
    - export http_proxy=http://proxy:port
    - export https_proxy=https://proxy:port
  -(Windows)
    - set http_proxy=http://proxy:port
    - set https_proxy=https://proxy:port

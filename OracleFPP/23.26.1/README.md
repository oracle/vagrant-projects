# Oracle Fleet Patching and Provisioning (FPP) Vagrant project on VirtualBox or KVM/libVirt provider

###### Author: Ruggero Citton (<ruggero.citton@oracle.com>) - Orale RAC Pack, Cloud Innovation and Solution Engineering Team

This directory contains Vagrant build files to provision automatically
26ai Grid Infrastructure and FPP Server host + (optional) an Oracle FPP target, using Vagrant, Oracle Linux 9 and shell scripts.
![](.images/OracleFPP.png)

## Prerequisites

1. Read the [prerequisites in the top level README](../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM
1. You need to download Database binary separately

## Free disk space requirement

- Grid Infrastructure and Database binary zip under "./ORCL_software": ~5.5 Gb
- Grid Infrastructure + RDBMS for GIMR on u01 vdisk (node1, location set by `u01_disk`): ~14 Gb
- OS guest vdisk (node1/node2) located on default VirtualBox VM location: ~2.5 Gb
  - In case of KVM/libVirt provider, the disk is created under `storage pool = "storage_pool_name"`
  - In case of VirtualBox
    - Use `VBoxManage list systemproperties |grep folder` to find out the current VM default location
    - Use `VBoxManage setproperty machinefolder <your path>` to set VM default location
- Dynamically allocated storage for ASM shared virtual disks (node1, location set by `asm_disk_path`): ~24 Gb

## 📦 Shared installer repository (`_ORCL_software/`)

The Oracle installer zips are multi-GB and identical across labs. Instead of
copying them into this project's `ORCL_software/`, you can drop each zip
**once** into the shared repository at the root of the Vagrant tree
([`_ORCL_software/`](../../_ORCL_software/README.md)). Every lab resolves
each zip **central-first, then this project's `ORCL_software/`** (which still
works and overrides the shared copy). Inside the guest the repo is mounted
read-only at `/software`.

| Where you put the zip | Effect |
|-----------------------|--------|
| `_ORCL_software/` | Shared by **all** labs — no duplication |
| this project's `ORCL_software/` | Used here only, **overrides** the shared copy |
| *(repo empty / absent)* | Behaves exactly as before |

Point the labs at a different location with `export ORCL_SOFTWARE_REPO=/path`.

## Memory requirement

- Deploy one Grid Infrastructure and FPP Server (host1) at least 12Gb are required
- Deploy OL8 host2 (optional) as Oracle FPP target at least 6Gb are required

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects.git`
2. Change into OracleFPP folder (`/repo clone path/vagrant-projects/RACPack/OracleFPP`)
3. Download Grid Infrastructure and Database (optional) binary from OTN into `./ORCL_software` folder (*)
4. Run `vagrant up`
5. Connect to Oracle FPP Server (node1).
6. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

(*) Download Grid Infrastructure and Database binary 26ai from OTN into `ORCL_software` folder
https://www.oracle.com/database/technologies/oracle-database-software-downloads.html

    Accept License Agreement
    go to version 26ai for Linux x86-64 you need -> "See All", example:

    * Oracle Database 26ai Grid Infrastructure (23.26.1) for Linux x86-64
        LINUX.X64_2326100_grid_home.zip (1,089,544,451 bytes)
        (sha256sum - 2deb199610357780ebb4d1213d6aa52df1694c7b12bd21f9e02dc3f9c992cd61)

    * Oracle Database 26ai (23.26.1) for Linux x86-64 (required with 26ai FPP)
       LINUX.X64_2326100_db_home.zip (2,406,058,543 bytes)
       (sha256sum - 2a5d2583df076209e624dff750829f9a562473c27c8f926d546cf9ad2a1a2efd)

Note: due to ACFS FPP usage, kernel-uek-6.12.10 is in use

## Customization

You can customize your Oracle environment by amending the parameters in the configuration file: `./config/vagrant.yml`
The following can be customized:

#### host1

- `vm_name`          : VM Guest partial name. The full name will be <prefix_name>-<vm_name>
- `mem_size`         : VM Guest memory size Mb (minimum 12Gb --> 12288)
- `cpus`             : VM Guest virtual cores
- `public_ip`        : VM public ip.
- `vip_ip`           : Oracle RAC VirtualIP (VIP).
- `private_ip`       : VM private ip
- `scan_ip1`         : Oracle RAC SCAN IP1
- `scan_ip2`         : Oracle RAC SCAN IP2
- `scan_ip3`         : Oracle RAC SCAN IP3
- `gns_IP`           : Oracle RAC GNS (FPP requirement)
- `ha_vip`           : Oracle RAC HA_VIP (FPP requirement)
- `storage_pool_name`: KVM/libVirt storage pool name
- `u01_disk`:          VirtualBox Oracle binary virtual disk (u01) file path


#### host2

- `vm_name`          : VM Guest partial name. The full name will be <prefix_name>-<vm_name>
- `mem_size`         : VM Guest memory size Mb (minimum 6Gb --> 6144)
- `cpus`             : VM Guest virtual cores
- `public_ip`        : VM public ip.
- `storage_pool_name`: KVM/libVirt storage pool name
- `u01_disk`:          VirtualBox Oracle binary virtual disk (u01) file path
- `deploy`           : It can be 'true' or 'false'. Using false node2 deploy will be skipped.

#### shared network

- `prefix_name`      : VM Guest prefix name (the GI cluster name will be: <prefix_name>-c')
- `network`          : It can be 'hostonly' or 'public'.
  - In case of 'hostonly', the guest VMs are using "host-Only" network defined as 'vboxnet0'
  - In case of 'public' a bridge network will be setup ('netmask' and 'gateway' are required). During startup the bridge network is required
- `bridge_nic`       : KVM/libVirt bridge NIC, required in case of 'public' network
- `netmask`          : Required in case of 'public' network
- `gateway`          : Required in case of 'public' network
- `dns_public_ip`    : Required in case of 'public' network
- `domain`           : VM Guest domain name

#### shared storage

- `storage_pool_name`: KVM/libVirt Oradata dbf KVM storage pool name
- `oradata_disk_path`: VirtualBox Oradata dbf path
- `asm_disk_num`     : Oracle RAC Automatic Storage Manager virtual disk number (min 4)
- `asm_disk_size`    : Oracle RAC Automatic Storage Manager virtual disk (max) size in Gb (at least 10)

#### environment

- `provider`         : It's defining the provider to be used: 'libvirt' or 'virtualbox'
- `grid_software`    : Oracle Database 18c Grid Infrastructure (18.3) for Linux x86-64 zip file (or above)
- `root_password`    : VM Guest root password
- `grid_password`    : VM Guest grid password
- `oracle_password`  : VM Guest oracle password
- `sys_password`     : Oracled RDBMS SYS password
- `ora_languages`    : Oracle products languages
- `opatch_software`  : Optional. OPatch zip (`p6880880_230000_Linux-x86-64.zip`); required if applying a Release Update
- `gi_ru_software`   : Optional. GI Release Update zip; a combo patch that also carries the RDBMS home patch

Applying a Release Update is opt-in. Leave `opatch_software` and `gi_ru_software` unset and both the GI
and RDBMS homes are installed at base release. Set **both** — they are validated as a pair, because the
OPatch shipped in the homes is too old to apply a modern RU — and add a SHA-256 entry for each zip to
`db_installer.sha256`. The GI RU is a combo patch that carries the RDBMS home patch as well, so one zip
covers both homes and there is no separate Database RU. The GI home is patched in place at install time
by `gridSetup.sh -applyRU`; the RDBMS home afterwards by `opatchauto`, before the GIMR is created.


#### Virtualbox provider Example1 (Oracle FPP Server available on host-only Virtualbox network):

    host1:
      vm_name: fpps
      mem_size: 16384
      cpus: 1
      private_ip:    192.168.200.101
      public_ip:     192.168.56.101
      vip_ip:        192.168.56.102
      scan_ip1:      192.168.56.105
      scan_ip2:      192.168.56.106
      scan_ip3:      192.168.56.107
      gns_ip:        192.168.56.108
      ha_vip:        192.168.56.109
      storage_pool_name: Vagrant_KVM

    host2:
      vm_name: fppc
      mem_size: 8192
      cpus: 1
      public_ip:  192.168.56.201
      storage_pool_name: Vagrant_KVM
      deploy: 'true'

    shared:
      prefix_name: fpp26-ol9
      # ---------------------------------------------
      network: hostonly
      domain: localdomain
      # ---------------------------------------------
      non_rotational: 'on'
      asm_disk_num:   8
      asm_disk_size: 10
      storage_pool_name: Vagrant_KVM
      # ---------------------------------------------

    env:
      provider: virtualbox
      # ---------------------------------------------
      gi_software:     LINUX.X64_2326100_grid_home.zip
      db_software:     LINUX.X64_2326100_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------

#### Virtualbox provider Example2: (Oracle FPP Server available on public network):

    host1:
      vm_name: fpps
      mem_size: 16384
      cpus: 2
      public_ip:  10.0.0.101
      vip_ip:     10.0.0.102
      scan_ip1:   10.0.0.105
      scan_ip2:   10.0.0.106
      scan_ip3:   10.0.0.107
      gns_ip:     10.0.0.108
      ha_vip:     10.0.0.109
      private_ip: 192.168.200.101
      storage_pool_name: Vagrant_KVM

    host2:
      vm_name: fppc
      mem_size: 8192
      cpus: 1
      public_ip:  10.0.0.201
      storage_pool_name: Vagrant_KVM
      deploy: 'false'

    shared:
      prefix_name:   fpp26-ol9
      # ---------------------------------------------
      network:       public
      netmask:       255.255.255.0
      gateway:       10.0.0.1
      dns_public_ip: 8.8.8.8
      domain:        mydomain.it
      # ---------------------------------------------
      non_rotational: 'on'
      asm_disk_num: 4
      asm_disk_size: 200
      storage_pool_name: Vagrant_KVM
      # ---------------------------------------------

    env:
      provider: virtualbox
      # ---------------------------------------------  
      gi_software:     LINUX.X64_2326100_grid_home.zip
      db_software:     LINUX.X64_2326100_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------

#### KVM/libVirt provider Example1 (Oracle FPP Server and FPP target on private network):

    host1:
      vm_name: fpps
      mem_size: 16384
      cpus: 1
      private_ip:    192.168.200.101
      public_ip:     192.168.125.101
      vip_ip:        192.168.125.102
      scan_ip1:      192.168.125.105
      scan_ip2:      192.168.125.106
      scan_ip3:      192.168.125.107
      gns_ip:        192.168.125.108
      ha_vip:        192.168.125.109
      storage_pool_name: Vagrant_KVM_Storage

      host2:
      vm_name: fppc
      mem_size: 8192
      cpus: 1
      public_ip:  192.168.125.201
      storage_pool_name: Vagrant_KVM_Storage
      deploy: 'true'

      shared:
      prefix_name:   fpp26-ol9
      # ---------------------------------------------
      network: hostonly
      domain: localdomain
      # ---------------------------------------------
      asm_disk_num:   8
      asm_disk_size: 10
      asm_lib_type: NONE
      storage_pool_name: Vagrant_KVM_Storage
      # ---------------------------------------------

      env:
      provider: libvirt
      # ---------------------------------------------
      gi_software:     LINUX.X64_2326100_grid_home.zip
      db_software:     LINUX.X64_2326100_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------

#### KVM/libVirt provider Example1 (Oracle FPP Server and FPP target on public network):

    host1:
      vm_name: fpps
      mem_size: 16384
      cpus: 1
      private_ip:    192.168.200.101
      public_ip:     192.168.125.101
      vip_ip:        192.168.125.102
      scan_ip1:      192.168.125.105
      scan_ip2:      192.168.125.106
      scan_ip3:      192.168.125.107
      gns_ip:        192.168.125.108
      ha_vip:        192.168.125.109
      storage_pool_name: Vagrant_KVM_Storage

      host2:
      vm_name: fppc
      mem_size: 8192
      cpus: 1
      public_ip:  192.168.125.201
      storage_pool_name: Vagrant_KVM_Storage
      deploy: 'true'

      shared:
      prefix_name:   fpp26-ol9
      # ---------------------------------------------
      network:       hostonly
      bridge_nic:    br0
      netmask:       255.255.255.0
      gateway:       10.0.0.1
      dns_public_ip: 8.8.8.8
      domain:        localdomain
      # ---------------------------------------------
      asm_disk_num:   8
      asm_disk_size: 10
      storage_pool_name: Vagrant_KVM_Storage
      # ---------------------------------------------

      env:
      provider: libvirt
      # ---------------------------------------------
      gi_software:     LINUX.X64_2326100_grid_home.zip
      db_software:     LINUX.X64_2326100_db_home.zip
      # ---------------------------------------------
      root_password:   welcome1
      grid_password:   welcome1
      oracle_password: welcome1
      sys_password:    welcome1
      # ---------------------------------------------
      ora_languages:   en,en_GB
      # ---------------------------------------------

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

  - (Windows)
    - set http_proxy=http://proxy:port
    - set https_proxy=https://proxy:port

## FPP Commands to Test After Deployment

Based on the configuration described above, you can test the following Fleet Patching and Provisioning (FPP) commands after deployment.

> **Note 1:** The database and Grid Infrastructure binary ZIP files must be available in the `/vagrant/ORCL_software` directory.

> **Note 2:** If the environment has limited resources, consider setting the following Java environment variables for the `grid` user before running `rhpctl` commands:
>
> ```bash
> export JVM_ARGS="-Xms512m -Xmx512m"
> export _JAVA_OPTIONS="-XX:ParallelGCThreads=2"
> ```

> **Note 3:** You can connect to `host1` or `host2` by running:
>
> ```bash
> vagrant ssh host1
> ```
>
> or:
>
> ```bash
> vagrant ssh host2
> ```

> **Note 4:** The following are examples of FPP commands you may want to test.

### Import the Database Software Image

```bash
rhpctl import image \
  -image db_2326100 \
  -imagetype ORACLEDBSOFTWARE \
  -zip /vagrant/ORCL_software/LINUX.X64_2326100_db_home.zip
```

### Import the Grid Infrastructure Software Image

```bash
rhpctl import image \
  -image gi_2326100 \
  -imagetype ORACLEGISOFTWARE \
  -zip /vagrant/ORCL_software/LINUX.X64_2326100_grid_home.zip
```

### Add a Database Working Copy

```bash
rhpctl add workingcopy \
  -workingcopy wc_db_2326100 \
  -image db_2326100 \
  -user oracle \
  -groups OSBACKUP=dba,OSDG=dba,OSKM=dba,OSRAC=dba \
  -oraclebase /u01/app/oracle \
  -inventory /u01/app/oraInventory \
  -path /u01/app/oracle/product/2326100/dbhome_1 \
  -targetnode fppc \
  -root
```

Alternatively, without explicitly specifying the inventory location:

```bash
rhpctl add workingcopy \
  -workingcopy wc_db_2326100 \
  -image db_2326100 \
  -user oracle \
  -groups OSBACKUP=dba,OSDG=dba,OSKM=dba,OSRAC=dba \
  -oraclebase /u01/app/oracle \
  -path /u01/app/oracle/product/2326100/dbhome_1 \
  -targetnode fppc \
  -root
```

### Create a Container Database

The following command creates a single-instance container database named `ORCL` with two pluggable databases:

```bash
rhpctl add database \
  -workingcopy wc_db_2326100 \
  -dbname ORCL \
  -dbtype SINGLE \
  -cdb \
  -pdbName PDB \
  -numberOfPDBs 2 \
  -root
```

Additional FPP commands can be tested as needed.

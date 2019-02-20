# oracle12c-vagrant
A vagrant box that provisions Oracle Database automatically, using Vagrant, an Oracle Linux 7.3 box and a shell script.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
2. Change into the desired version folder
3. Download the installation zip files from OTN into this folder - first time only:
[http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
4. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have (a good) internet connection as the scripts will update the virtual box to the latest via `yum`.
   2. The Vagrant file allows for customization, if desired (see [Customization](#customization))
5. Connect to the database.
6. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Connecting to Oracle
* Hostname: `localhost`
* Port: `1521`
* SID: `ORCLCDB`
* PDB: `ORCLPDB1`
* OEM port: `5500`
* All passwords are auto-generated and printed on install

## Resetting password
You can reset the password of the Oracle database accounts by executing `/home/oracle/setPassword.sh <Your new password>`.

## Running scripts after setup
You can have the installer run scripts after setup by putting them in the `userscripts` directory below the directory where you have this file checked out. Any shell (`.sh`) or SQL (`.sql`) scripts you put in the `userscripts` directory will be executed by the installer after the database is set up and started. Only shell and SQL scripts will be executed; all other files will be ignored. These scripts are completely optional.

Shell scripts will be executed as root. SQL scripts will be executed as SYS. SQL scripts will run against the CDB, not the PDB, unless you include an `ALTER SESSION SET CONTAINER = <pdbname>` statement in the script.

To run scripts in a specific order, prefix the file names with a number, e.g., `01_shellscript.sh`, `02_tablespaces.sql`, `03_shellscript2.sh`, etc.

## Other info

* If you need to, you can connect to the machine via `vagrant ssh`.
* You can `sudo su - oracle` to switch to the oracle user.
* The Oracle installation path is `/opt/oracle/` by default.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.

### Customization
You can customize your Oracle environment by amending the environment variables in the `Vagrantfile` file.
The following can be customized:
* `ORACLE_BASE`: `/opt/oracle/`
* `ORACLE_HOME`: `/opt/oracle/product/12.2.0.1/dbhome_1`
* `ORACLE_SID`: `ORCLCDB`
* `ORACLE_PDB`: `ORCLPDB1`
* `ORACLE_CHARACTERSET`: `AL32UTF8`
* `ORACLE_EDITION`: `EE` | `SE2`
* `ORACLE_PWD`: `auto generated`
* `SYSTEM_TIMEZONE`: `automatically set (see below)`
  * The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  * The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  * When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  * You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

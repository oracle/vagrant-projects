# oracle-18c-apex
A vagrant box that provisions Oracle Database XE 18.4 with Oracle Application Expres (APEX) automatically, using Vagrant, an Oracle Linux 7 box and a shell script.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
2. Change into the OracleAPEX folder
3. Download the Oracle Database XE 18.4 installation rpm file from OTN into this folder - first time only:
[https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html)
4. Download the Oracle APEX into this folder - first time only:
[https://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html](https://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html)
5. Download Oracle Rest Data Services (ORDS) into this folder - first time only:
[https://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html](https://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html)
4. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have (a good) internet connection as the scripts will update the virtual box to the latest via `yum`.
   2. The Vagrant file allows for customization, if desired (see [Customization](#customization))
5. Connect to the database.
6. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Connecting to Oracle
* Hostname: `localhost`
* Port: `1521`
* SID: `XE`
* PDB: `XEPDB1`
* OEM port: `5500`
* APEX Admin port: `8080` (on Host system)
* All passwords are auto-generated and printed on install

## Other info

* If you need to, you can connect to the machine via `vagrant ssh`.
* You can `sudo su - oracle` to switch to the oracle user.
* The Oracle installation path is `/opt/oracle/` by default.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.

### Customization
You can customize your Oracle environment by amending the environment variables in the `Vagrantfile` file.
The following can be customized:
* `ORACLE_CHARACTERSET`: `AL32UTF8`
* `ORACLE_PWD`: `auto generated`
* `SYSTEM_TIMEZONE`: `automatically set (see below)`
  * The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  * The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  * When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  * You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

### Oracle Application Express Access
Oracle Application Express Access will be available on the host OS by accessing following URL:

* `http://localhost:8080/ords/`
* `Workspace: internal`
* `User: admin`
* `Password: <See auto-generated password>`

At the first login you'll be forced to change the default `admin` password.

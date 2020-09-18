# oracle19c-gg-vagrant

A Vagrant project that provisions Oracle Database along with Golden Gate automatically, using Vagrant, an Oracle Linux 7 box, and a shell script.

## Prerequisites

1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the desired version folder
3. Download the Oracle 19c Database (LINUX.X64_193000_db_home.zip) installation zip files from oracle edelivery into this folder - first time only: [edelivery](https://www.oracle.com/database/technologies/oracle-database-software-downloads.html#19c)
4. Download the installation zip for golden gate (191004_fbo_ggs_Linux_x64_shiphome.zip) & golden gate for Big Data (OGG_BigData_Linux_x64_19.1.0.0.1) into this folder - first time only: [edelivery](https://www.oracle.com/middleware/technologies/goldengate-downloads.html)
5. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have (a good) internet connection as the scripts will update the virtual box to the latest via `yum`.
   2. The Vagrant file allows for customization, if desired (see [Customization](#customization))
6. Connect to the database.
7. You can shut down the box via the usual `vagrant halt` and the start it up again via `vagrant up`.

## Connecting to Oracle

- Hostname: `localhost`
- Port: `1521`
- SID: `ORCLCDB`
- PDB: `ORCLPDB1`
- OEM port: `5500`
- All passwords are auto-generated and printed on install

## Resetting password

You can reset the password of the Oracle database accounts by executing `/home/oracle/setPassword.sh <Your new password>`.

## Connecting to Apache Kafka

- Hostname: `localhost`
- Zookeeper: `2181`
- Kafka-Broker: `9092`

## Other info

- If you need to, you can connect to the machine via `vagrant ssh`.
- You can `sudo su - oracle` to switch to the oracle user.
- The Oracle installation path is `/opt/oracle/` by default.
- On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.
- Golden Gate is available at location `/u01/ogg` & `/u01/oggbd` console is accessible using `./ggsci` command inside the folder.
- Apache Kafka is available at location `/usr/local/kafka/kafka-xxxx`

### Customization

You can customize your Oracle environment by amending the environment variables in the `Vagrantfile` file.
The following can be customized:

- `ORACLE_BASE`: `/opt/oracle/`
- `ORACLE_HOME`: `/opt/oracle/product/12.2.0.1/dbhome_1`
- `ORACLE_SID`: `ORCLCDB`
- `ORACLE_PDB`: `ORCLPDB1`
- `ORACLE_CHARACTERSET`: `AL32UTF8`
- `ORACLE_EDITION`: `EE` | `SE2`
- `ORACLE_PWD`: `auto generated`
- `JAVA_VERSION`: `1.8.0`
- `SCALA_VERSION`: `2.12`
- `KAFKA_VERSION`: `2.6.0`
- `APACHE_ZOOKEEPER_PORT`: `2181`
- `APACHE_KAFKA_PORT`: `9092`
- `ORACLE_DB_SETUP_FIL`: `linux*122*.zip`
- `ORACLE_GG_SETUP_FILE`: `*ggs_Linux*.zip`
- `ORACLE_GG_BD_SETUP_FILE`: `*BigData_Linux*.zip`

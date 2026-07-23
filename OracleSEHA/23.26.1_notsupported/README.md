# Oracle SEHA Lab
## Oracle Database 26ai (23.26.1) on Oracle Linux 9

This directory provisions an Oracle Standard Edition High Availability (SEHA)
lab from a single `vagrant up`.

![Topology](.images/OracleSEHA.png)

The build is intentionally SEHA-only:

- two Oracle Linux 9 VMs: `host1` and `host2`
- two-node Grid Infrastructure cluster with SCAN, VIPs, private interconnect, and ASM
- RDBMS software installed as **SE2**, separately on each node (the SE2 home is
  single-instance and cannot be pushed as a cluster home)

> **Known blocker:** the tested 23.26.1 (Oracle AI Database 26ai) Linux x86-64
> `db_home.zip` ships **Enterprise Edition only**, and SEHA is an SE2-only
> feature. This project therefore cannot complete on that media — see
> [Media limitation](#media-limitation) below.
- SEHA database created with `dbca -databaseConfigType SEHA -sehaNodeList node1,node2`
- shared ASM storage with `+DATA` and `+RECO`
- optional Release Update: 23.26.1 already ships SEHA, so patching is opt-in


> This is a lab build, not a hardened production blueprint. The defaults include
> demo passwords, `firewalld` disabled, `/etc/hosts`-driven name resolution, and
> silent installers invoked with `-ignorePrereq`.

## At a Glance

| Area | Value |
| --- | --- |
| Virtualization | VirtualBox or KVM/libvirt |
| Operating system | `oraclelinux/9` |
| GI / DB version | 23.26.1.0 |
| Database edition | `SE2` required — **but the tested 23.26.1 media ships EE only** (see below) |
| Database type | SEHA (`dbca -databaseConfigType SEHA -sehaNodeList`) |
| Release Update | Optional — set `env.opatch_software` + `env.gi_ru_software` to apply one |
| Nodes | `host1`, `host2` |
| ASM diskgroups | `DATA` on P1 partitions, `RECO` on P2 partitions |
| Runtime env file | `/etc/opt/oracle-seha/setup.env` |
| Hook model | `userscripts/*.sh` as `root`, `userscripts/*.sql` as `SYSDBA` |

## Quick Start

1. Create your local config:

   ```bash
   cd SEHA
   cp config/vagrant.yml.example config/vagrant.yml
   ```

2. Place both Oracle 23ai installer zips under `ORCL_software/`:

   ```text
   ORCL_software/LINUX.X64_2326100_grid_home.zip
   ORCL_software/LINUX.X64_2326100_db_home.zip
   ```

3. Confirm `db_installer.sha256` matches the installers:

   ```bash
   sha256sum ORCL_software/LINUX.X64_2326100_grid_home.zip
   sha256sum ORCL_software/LINUX.X64_2326100_db_home.zip
   ```

4. Launch the lab:

   ```bash
   vagrant up
   ```

5. Connect to the guests:

   ```bash
   vagrant ssh host1
   vagrant ssh host2
   ```

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

## Configuration

All runtime settings live in `config/vagrant.yml`.

| Key | Default | Notes |
| --- | --- | --- |
| `env.provider` | `virtualbox` | Must be `virtualbox` or `libvirt` |
| `env.prefix_name` | `seha26-ol9` | Drives VM, cluster, ASM disk, and SCAN names |
| `env.domain` | `localdomain` | Used for host, VIP, private, and SCAN names |
| `host1.vm_name` | `node1` | Primary orchestration node |
| `host2.vm_name` | `node2` | Secondary node and initial shared-disk partition owner |
| `env.asm_disk_num` | `4` | Minimum 4 shared ASM disks |
| `env.asm_disk_size` | `20` | GB per shared ASM disk |
| `env.p1_ratio` | `80` | Percentage assigned to DATA partitions |
| `env.db_name` | `SEHA26` | Global database name and SID |
| `env.pdb_name` | `PDB1` | First PDB name; always required |
| `env.pdb_password` | *(demo value)* | PDB admin password; always required |
| `env.db_recovery_file_dest_size` | `4G` | Passed to DBCA |
| `env.opatch_software` | *(unset)* | Optional; OPatch zip, required if applying an RU |
| `env.gi_ru_software` | *(unset)* | Optional; GI RU zip (a combo patch that also carries the DB home patch) |

The database mode is not configurable in this project. GI Management Repository
is always skipped; `env.nomgmtdb` is not supported. The database is always a
container database, so `env.cdb` is not supported either and `env.pdb_name` /
`env.pdb_password` are always required. The `Vagrantfile` always passes
`DB_TYPE=SEHA`, `ORESTART=false`, `CDB=true`, and `DB_INSTALL_EDITION=SE2` to
the provisioning scripts.

### Media limitation

SEHA requires a Standard Edition 2 database home. The 23.26.1 (Oracle AI
Database 26ai) Linux x86-64 `db_home.zip` carries no SE2 components, and
`runInstaller` rejects `installEdition=SE2` with:

```
[FATAL] [INS-35464] The installer does not support installing the
        Standard Edition 2 of Oracle Database.
```

Installing EE and asking dbca for SEHA anyway does not work either. Tested on a
live two-node cluster with EE homes installed on both nodes:

```
[FATAL] [DBT-10604] Standard Edition High Availability database creation is
        not supported in this environment.
  CAUSE: The specified Oracle home does not support Standard Edition High
         Availability database creation.
```

So both doors are shut: there is no SE2 to install (INS-35464), and an EE home is
refused by dbca (DBT-10604).

Two things make this easy to misdiagnose, so both are worth stating plainly:

- `install/response/db_install.rsp` documents only `EE`. That is **accurate** —
  the comment block is generated per-media. Trust it.
- `install/jlib/instdb.jar` contains `<xsd:enumeration value="SE2"/>`. That is a
  **schema shared across releases**; it says nothing about what this shiphome
  carries, and is *not* evidence that SE2 can be installed.

`Vagrantfile` therefore pins `DB_INSTALL_EDITION = 'EE'`, and `scripts/setup.sh`
fails immediately on the SE2 mismatch rather than spending ~30 minutes on Grid
Infrastructure before hitting INS-35464 at the RDBMS install.

Everything else in this project is already SEHA-correct. If Oracle ships an SE2
shiphome for this release, set `DB_INSTALL_EDITION = 'SE2'` in the `Vagrantfile`
and the pipeline should run through. For a working SEHA lab today, use the
`19.3.0` or `21.3.0` project.

### How the SEHA database is created

23.26.1's `dbca` supports SEHA natively, so the database is created in one step
by `scripts/17_create_database.sh`:

```bash
dbca -silent -createDatabase ... -databaseConfigType SEHA -sehaNodeList node1,node2
```

`dbca` registers the failover configuration itself, so no follow-up
`srvctl modify database -node` is required.

> This is release-specific. The sibling 19c and 21c projects create the database
> as `SINGLE` and then add the candidate node list with
> `srvctl modify database -node`, because their `dbca` accepts only
> `< SINGLE | RAC | RACONENODE >` and has no `-sehaNodeList`.

The `env.opatch_software` and `env.gi_ru_software` keys must be set together or
not at all; each zip also needs an entry in `db_installer.sha256`.

## Password Overrides

The YAML password values are demo placeholders. You can override them at run
time:

```bash
export ORACLE_SEHA_ROOT_PASSWORD='strong-root-password'
export ORACLE_SEHA_GRID_PASSWORD='strong-grid-password'
export ORACLE_SEHA_ORACLE_PASSWORD='strong-oracle-password'
export ORACLE_SEHA_SYS_PASSWORD='strong-sys-password'
export ORACLE_SEHA_PDB_PASSWORD='strong-pdb-password'
vagrant up
```

## Provisioning Pipeline

The orchestration entrypoint is `scripts/setup.sh`. It writes
`/etc/opt/oracle-seha/setup.env`, sources `scripts/_common.sh`, and runs these
numbered stages:

| Step | Script | Purpose |
| --- | --- | --- |
| 01 | `scripts/01_install_os_packages.sh` | Installs OS and GI prerequisites |
| 02 | `scripts/02_setup_u01.sh` | Creates GPT, LVM, XFS, and `/u01` |
| 03 | `scripts/03_setup_hosts.sh` | Rewrites host resolution and SCAN dnsmasq records |
| 04 | `scripts/04_setup_chrony.sh` | Disables time daemons so CTSS runs active |
| 05 | `scripts/05_setup_users.sh` | Creates users, groups, homes, limits, and profiles |
| 06 | `scripts/06_setup_shared_disks.sh` | Partitions shared disks and creates ASM udev names |
| 07 | `scripts/07_extract_gi.sh` | Extracts the Grid home and stages the RU when configured |
| 08 | `scripts/08_setup_user_equ.sh` | Builds SSH equivalence for `grid`, `oracle`, and `root` |
| 10 | `scripts/10_gi_installation.sh` | Runs `gridSetup.sh`, adding `-applyRU` when an RU is configured |
| 11 | `scripts/11_gi_root.sh` | Runs GI root scripts locally and on node2 |
| 12 | `scripts/12_gi_config.sh` | Runs `gridSetup.sh -executeConfigTools` |
| 13 | `scripts/13_make_reco_dg.sh` | Ensures `DATA` and `RECO` are mounted on both nodes |
| 14 | `scripts/14_extract_db.sh` | Extracts the RDBMS home **on each node**; stages the RU when configured |
| 15 | `scripts/15_db_software_installation.sh` | Silent SE2 software-only install — run separately on each node |
| 16 | `scripts/16_patch_db_home.sh` | Applies the RU via `opatchauto`; no-op without an RU |
| 17 | `scripts/17_create_database.sh` | Creates the SEHA database with `dbca -databaseConfigType SEHA -sehaNodeList` |
| 18 | `scripts/18_check_database.sh` | Validates Clusterware registration with `srvctl` |

## Validation

After `vagrant up`, useful in-guest checks are:

```bash
vagrant ssh host1

sudo cat /etc/opt/oracle-seha/setup.env
sudo su - grid
asmcmd lsdg

sudo su - oracle
srvctl config database -d SEHA26
srvctl status database -d SEHA26
```

Repeat the `srvctl` checks from `host2` to confirm both nodes see the same
Clusterware-managed database resource.

## Cleanup

Destroy the VMs and remove lab-owned ASM and `/u01` disks:

```bash
cleanup/cleanup.sh --force
```

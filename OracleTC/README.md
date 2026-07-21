# Vagrant projects: Oracle Data Guard (DG)

This directory contains Vagrant projects that automatically provision a
two-node Oracle Data Guard lab (primary + physical standby). Each project is
self-contained and picks an Oracle Linux base box suited to its target
Oracle Database release.

## Layout

The project tree is indexed by **Oracle Database version**. Each folder is a
fully independent Vagrant project:

| Folder     | Oracle DB      | OS base    | Installer zip (place under `ORCL_software/`) |
| ---------- | -------------- | ---------- | -------------------------------------------- |
| `19.3.0/`  | 19c (19.3.0)   | OL 7       | `LINUX.X64_193000_db_home.zip`               |
| `21.3.0/`  | 21c (21.3.0)   | OL 8       | `LINUX.X64_213000_db_home.zip`               |
| `23.26.1/` | 23ai (23.26.1) EE | OL 9    | `LINUX.X64_2326100_db_home.zip`              |

The legacy OS-indexed layout (`OL7/`, `OL8/`, `OL9/`) is retained for
backwards compatibility but new work should target the version-indexed
folders above.

## Prerequisites

Read the [prerequisites in the top-level README](../README.md#prerequisites)
to install Vagrant with either **VirtualBox** or **KVM/libvirt**.

## Getting started

```bash
git clone https://github.com/oracle/vagrant-projects.git
cd vagrant-projects/OracleDG/<version>        # e.g. 21.3.0
# 1. Download the matching installer zip into ORCL_software/
# 2. (Optional) edit config/vagrant.yml
vagrant up
```

`vagrant halt` / `vagrant up` stops and restarts the lab. A full reset is
`vagrant destroy -f` followed by deleting the project's `*.vdi` files (on
VirtualBox) or wiping the libvirt storage pool entries.

Each folder has its own `README.md` with version-specific details
(RU requirements, memory/disk sizing, preinstall package notes).

## Security notes

- Default passwords in `config/vagrant.yml` are **demo only** (`welcome1`).
  Replace them — or override via `ORACLE_DG_{ROOT,ORACLE,SYS,PDB}_PASSWORD`
  environment variables — before any real use.
- The provisioner writes `config/setup.env` with mode `0600`; it contains
  cleartext passwords used during bootstrap only. It is not committed
  (gitignored-by-convention via the project `.gitignore` patterns) and is
  regenerated on each `vagrant up`.
- **Oracle Database Free Edition does not support Data Guard.** The
  `23.26.1/` project requires the Enterprise Edition installer.

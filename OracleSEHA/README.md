# Oracle SEHA Vagrant projects

This directory contains Vagrant projects to provision Oracle database lab
environments automatically, using Vagrant and shell scripts.

Available projects:

| Directory | Purpose |
| --- | --- |
| `19.3.0` | Oracle Standard Edition High Availability (SEHA) based on 19.3 |
| `21.3.0` | Oracle Standard Edition High Availability (SEHA) based on 21.3 |

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up either Vagrant with either VirtualBox or KVM

## 📦 Shared installer repository (`_ORCL_software/`)

The Oracle installer zips are multi-GB and identical across labs. Instead of
copying them into this project's `ORCL_software/`, you can drop each zip
**once** into the shared repository at the root of the Vagrant tree
([`_ORCL_software/`](../_ORCL_software/README.md)). Every lab resolves
each zip **central-first, then this project's `ORCL_software/`** (which still
works and overrides the shared copy). Inside the guest the repo is mounted
read-only at `/software`.

| Where you put the zip | Effect |
|-----------------------|--------|
| `_ORCL_software/` | Shared by **all** labs — no duplication |
| this project's `ORCL_software/` | Used here only, **overrides** the shared copy |
| *(repo empty / absent)* | Behaves exactly as before |

Point the labs at a different location with `export ORCL_SOFTWARE_REPO=/path`.

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the desired project folder, for example `19.3.0`
3. Run `vagrant up`
4. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

**For more information please check the individual README within each folder!**

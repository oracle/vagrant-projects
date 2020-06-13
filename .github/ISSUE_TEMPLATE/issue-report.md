---
name: Issue report
about: Create an issue to help us improve
title: ''
labels: ''
assignees: ''

---

**Describe the issue**

A clear and concise description of what the issue is.  
Explain what commands you ran, what you expected to happen and what actually happened.

**Environment (please complete the following information):**

- Host OS: [e.g. Oracle Linux 8, macOS 10.14.6, Windows 10 Pro, ...]
- Kernel version (for Linux host): [run `uname -a`]
- Vagrant version: [e.g. 2.2.9]
- Vagrant provider:
  - For VirtualBox:
    - VirtualBox version: [e.g. 6.1.8r137981 -- run `vboxmanage -v`]
  - For libvirt:
    - Vagrant-libvirt plugin version: [e.g. 0.1.2 -- run `vagrant plugin list`]
    - QEMU and libvirt version:  
      If you have `virsh` installed run `virsh -c qemu:///system version --daemon`  
      Alternatively query your package manager with e.g.  
        `rpm -q qemu-kvm libvirt`,  
        `dpkg -l qemu-kvm libvirt\* | grep ^ii`, ...
- Vagrant project:  [e.g. OLCNE, OracleDatabase/19.3.0, ...]

**Additional information**

Add any other information about the issue here (console log, ...).

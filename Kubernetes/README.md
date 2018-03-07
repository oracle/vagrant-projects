# Vagrantfile to setup a Kubernetes Cluster on Oracle Linux 7
This Vagrantfile will provision a Kubernetes cluster with one master and _n_
worker nodes (2 by default).

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://vagrantup.com/)
1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com)
and accept the _Oracle Standard Terms and Restrictions_ for the
_Container Services_ Business Area.

## Quick start
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
1. Change into the `vagrant-boxes/Kubernetes` folder
1. Run `vagrant up master; vagrant ssh master`
1. Within the master guest, run as `root`:
`/vagrant/scripts/kubeadm-setup-master.sh`  
You will be asked to log in to the Oracle Container Registry
1. Run `vagrant up worker1; vagrant ssh worker1`
1. Within the worker1 guest, run as `root`:
`/vagrant/scripts/kubeadm-setup-worker.sh`  
You will be asked to log in to the Oracle Container Registry
1. Repeat the last 2 steps for worker2

Your cluster is ready!  
Within the master guest you can check the status of the cluster (as the
`vagrant` user). E.g.:
- `kubectl cluster-info`
- `kubectl get nodes`
- `kubectl get pods --namespace=kube-system`

## About the Vagrantfile

The Vagrant provisioning script uses the _Oracle Linux 7 Preview_ and
_Add-ons_ channels for both Docker Engine and Kubernetes (latest version is
select by `yum`).

The VMs communicate via a private network:

- Master node: 192.168.99.100 / master.vagrant.vm
- Worker node i: 192.168.99.(100+i) / worker_i_.vagrant.vm

The Vagrant provisioning script pre-loads Kubernetes and satisfies the
pre-requisites.
It does **not** run `kubeadm-setup.sh` as this requires authentication to the
[Oracle Container Registry](https://container-registry.oracle.com). This is
done by the `kubeadm-setup-master.sh` and `kubeadm-setup-worker.sh` helper
scripts.

## Configuration
The Vagrantfile can be used _as-is_; there are a couple of parameters you
can set to tailor the installation to your needs.

- `NB_WORKERS` (default: 2): the number of worker nodes to provision.
- `MANAGE_FROM_HOST` (default: `false`): when `true`, Vagrant will bind port
`6443` from the master node to the host.
This allows you to manage the cluster from the host itself using the generated
`admin.conf` file (assuming `kubectl` is installed on the host).
- `BIND_PROXY` (default: `true`): when `true`, Vagrant will bind the Kubernetes
Proxy port from the master node to the host. Useful to access the
Dashboard or any other application from _outside_ the cluster.
It is an easier alternative to ssh tunnel.
- `MEMORY` (default: 2048): all VMs are provisioned with 2GB memory. This
can be slightly reduced if memory is a concern.

## Optional plugins
You might want to install the following Vagrant plugins:
- [vagrant-hosts](https://github.com/oscar-stack/vagrant-hosts): maintains
/etc/hosts for the guest VMs;
- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access Internet through proxy. See
plugin documentation for the configuration.

## Feedback
Please provide feedback of any kind via Github issues on this repository.

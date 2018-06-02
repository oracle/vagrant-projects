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
1. Within the master guest, run as `root`: <sup>[(\*)](#note-1)</sup>  
`/vagrant/scripts/kubeadm-setup-master.sh`  
You will be asked to log in to the Oracle Container Registry
1. Run `vagrant up worker1; vagrant ssh worker1`
1. Within the worker1 guest, run as `root`: <sup>[(\*)](#note-1)</sup>  
`/vagrant/scripts/kubeadm-setup-worker.sh`  
You will be asked to log in to the Oracle Container Registry
1. Repeat the last 2 steps for worker2

Your cluster is ready!  
Within the master guest you can check the status of the cluster (as the
`vagrant` user). E.g.:
- `kubectl cluster-info`
- `kubectl get nodes`
- `kubectl get pods --namespace=kube-system`

<a id="note-1"></a>(\*) If you have a password-less local container registry
skip steps 4 and 6  (see [Local Registry](#local-registry)).

## About the Vagrantfile

The VMs communicate via a private network:

- Master node: 192.168.99.100 / master.vagrant.vm
- Worker node i: 192.168.99.(100+i) / worker_i_.vagrant.vm

The Vagrant provisioning script pre-loads Kubernetes and satisfies the
pre-requisites.
Unless you have a password-less [Local Registry](#local-registry) it does
**not** run `kubeadm-setup.sh` as this requires authentication to the
[Oracle Container Registry](https://container-registry.oracle.com). This is
done by the `kubeadm-setup-master.sh` and `kubeadm-setup-worker.sh` helper
scripts.

## Configuration
The Vagrantfile can be used _as-is_; there are a couple of parameters you
can set to tailor the installation to your needs.

- `NB_WORKERS` (default: 2): the number of worker nodes to provision.
- `USE_PREVIEW` (default: `true`): when `true`, Vagrant provisioning script
will use the _Oracle Linux 7 Preview_ and _Add-ons_ channels for both Docker
Engine and Kubernetes (latest version is select by `yum`).  
Otherwhise it will only use the _Add-ons_ channel.
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

### Registry Mirror
If you are using an [Oracle Container Registry Mirror](https://docs.oracle.com/cd/E52668_01/E88884/html/requirements-registry-mirror.html)
you can use the following two parameters:
- `KUBE_REPO`: registry hostname
- `KUBE_PREFIX`: image prefix for Kubernetes container images

__Example__: to use the Oracle Container Registry mirror in Frankfurt, define
```ruby
KUBE_REPO = "container-registry-fra.oracle.com"
KUBE_PREFIX = "/kubernetes"
```

### Local Registry
You can also setup a [Local Registry](https://docs.oracle.com/cd/E52668_01/E88884/html/requirements-registry-local.html).
In addition to the `KUBE_REPO` and `KUBE_PREFIX` parameters you can also define:
- `KUBE_LOGIN` (default: `undefined`/`true`): set to `false` if your registry
does not require authentication.
- `KUBE_SSL` (default: `undefined`/`true`): set to `false` if your registry
does not use SSL.

__Example__: you have a local repository on host.example.com, without authentication and SSL is not configured; this registry has been populated with:
```shell
kubeadm-registry.sh --to host.example.com:5000/kubernetes --version 1.9.1
```
You will then define in tour Vagrantfile:
```ruby
KUBE_REPO = "host.example.com:5000"
KUBE_PREFIX = "/kubernetes"
KUBE_LOGIN = false
KUBE_SSL = false
```

__Note__: if you have a password-less registry (`KUBE_LOGIN = false`) the
Vagrant provisioning script will also run the `kubeadm-setup-master.sh` / `kubeadm-setup-worker.sh` scripts. In other words, your Kubernetes
cluster will be fully operational after a `vagrant up`!

See also the [Container Registry Vagrantfile](../ContainerRegistry) to run a
local registry in Vagrant.

## Optional plugins
You might want to install the following Vagrant plugins:
- [vagrant-hosts](https://github.com/oscar-stack/vagrant-hosts): maintains
/etc/hosts for the guest VMs;
- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access Internet through proxy. See
plugin documentation for the configuration.

## Feedback
Please provide feedback of any kind via Github issues on this repository.

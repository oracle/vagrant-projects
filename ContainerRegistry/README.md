# Vagrantfile to run a local Container Registry on Oracle Linux 7
This simple Vagrantfile will provision an Oracle Linux 7 box running a local
Container Registry.

It can be used as cache for the Oracle Container Registry, in particular for
the Kubernetes containers.

## Prerequisites
1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://vagrantup.com/)
1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com)
and accept the _Oracle Standard Terms and Restrictions_ for the
_Container Services_ Business Area.

## Quick start
1. Clone this repository `git clone https://github.com/oracle/vagrant-boxes`
1. Change into the `vagrant-boxes/ContainerRegistry` folder
1. Run `vagrant up; vagrant ssh`

Your local container registry is up and running!

## Configuration
The Vagrantfile can be used _as-is_; there are a couple of parameters you
can set to tailor the installation to your needs.

### How to configure
There are several ways to set parameters:
1. Update the Vagrantfile. This is straightforward; the downside is that you
will loose changes when you update this repository.
1. Use environment variables. Might be difficult to remember the parameters
used when the box was instantiated.
1. Use the `.env`/`.env.local` files (requires
[vagrant-env](https://github.com/gosuri/vagrant-env) plugin). Configure
your Registry by editing the `.env` file; or better copy `.env` to `.env.local`
and edit the latter one, it won't be overridden when you update this repository
and it won't mark your git tree as changed (you won't accidentally commit your
local configuration!)

Parameters are considered in the following order (first one wins):
1. Environment variables
1. `.env.local` (if [vagrant-env](https://github.com/gosuri/vagrant-env) plugin
is installed)
1. `.env` (if [vagrant-env](https://github.com/gosuri/vagrant-env) plugin
is installed)
1. Vagrantfile definitions

### Registry parameters
- `REGISTRY_IP` (default: 192.168.99.253): the VM will join the VirtualBox
private network using this IP.
- `REGISTRY_BIND` (default: undefined): if this variable is defined, Vagrant
will bind the registry port (5000) from the VM to the specified port on the
host, making the local registry available outside of the Vagrant environment.

### Use case: Registry Mirror for Kubernetes
We can use our local container registry to mirror the Kubernetes containers
for a faster deployment of a [Vagrant] Kubernetes cluster.  
The `scripts` directory contains the `kubeadm-setup-registry.sh` convenience
script for this task.

1. `vagrant ssh` in your registry VM
1. as `vagrant` user run:  
`/vagrant/scripts/kubeadm-setup-registry.sh`  
You will be asked to log in to the Oracle Container Registry.  
If you want to mirror from an [Oracle Container Registry Mirror](https://docs.oracle.com/cd/E52668_01/E88884/html/requirements-registry-mirror.html), use the `--from` parameter, e.g.:  
`/vagrant/scripts/kubeadm-setup-registry.sh --from container-registry-fra.oracle.com`

To use this local registry with the [Vagrant Kubernetes cluster](../Kubernetes),
define in the Kubernetes Vagrantfile:

```ruby
KUBE_REPO = "192.168.99.253:5000"
KUBE_PREFIX = "/kubernetes"
KUBE_LOGIN = false
KUBE_SSL = false
```

With our local registry there is no need anymore to provide
credentials when installing Kubernetes.
Vagrant provisioning script will also run the `kubeadm-setup-master.sh` /
`kubeadm-setup-worker.sh` scripts. In other words, your Kubernetes
cluster will be fully operational after a `vagrant up`!

## Optional plugins
You might want to install the following Vagrant plugin:
- [vagrant-env](https://github.com/gosuri/vagrant-env): loads environment
variables from .env files;
- [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VMs if you need to access Internet through proxy. See
plugin documentation for the configuration.

## Feedback
Please provide feedback of any kind via Github issues on this repository.

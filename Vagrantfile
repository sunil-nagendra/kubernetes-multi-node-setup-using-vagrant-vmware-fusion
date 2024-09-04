# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of nodes
NUM_CONTROLPLANE = 3
NUM_WORKERS = 2

# Define the fully qualified Kubernetes version
K8S_VERSION = "1.31.0-1.1"

# All Vagrant configuration is done below.
Vagrant.configure("2") do |config|
  # Base box
  config.vm.box = "bento/ubuntu-22.04"

  # Disable automatic box update checking
  config.vm.box_check_update = false

  # Configure controlplane nodes
  (1..NUM_CONTROLPLANE).each do |i|
    config.vm.define "controlplane#{i}" do |controlplane|
      controlplane.vm.hostname = "controlplane#{i}"
      controlplane.vm.network "private_network", ip: "192.168.50.#{10 + i}"
      controlplane.vm.provider "vmware_desktop" do |v|
        v.memory = 2048
        v.cpus = 2
      end
      controlplane.vm.provision "shell", path: "scripts/k8s_controlplane_setup.sh", args: ["controlplane#{i}", K8S_VERSION]
    end
  end

  # Configure worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.hostname = "worker#{i}"
      worker.vm.network "private_network", ip: "192.168.50.#{20 + i}"
      worker.vm.provider "vmware_desktop" do |v|
        v.memory = 2048
        v.cpus = 2
      end
      worker.vm.provision "shell", path: "scripts/k8s_worker_setup.sh", args: ["worker#{i}", K8S_VERSION]
    end
  end
end
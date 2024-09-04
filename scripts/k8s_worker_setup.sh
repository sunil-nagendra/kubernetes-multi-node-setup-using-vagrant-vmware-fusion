#!/bin/bash

NODE_NAME=$1
K8S_VERSION=$2

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#configure kernel parameters
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install containerd
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Configure containerd to use systemd as the cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes
sudo mkdir -p /etc/apt/keyrings
sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gpg bash-completion
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

# Setups for workers node
sudo sed -i "/${NODE_NAME}/d" /etc/hosts
IP=$(hostname -I | awk '{print $1}')
echo "${IP} ${NODE_NAME}" | sudo tee -a /etc/hosts > /dev/null
sudo tee -a /etc/hosts < /vagrant/scripts/controlplane_ip.txt > /dev/null

# Join the Kubernetes cluster
sudo bash /vagrant/scripts/worker_join_command.sh
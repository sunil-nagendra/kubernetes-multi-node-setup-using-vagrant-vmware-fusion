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

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

# Setups for controlplane1 node
if [ "$NODE_NAME" == "controlplane1" ]; then
  sudo sed -i "/${NODE_NAME}/d" /etc/hosts
  IP=$(hostname -I | awk '{print $1}')
  echo "${IP} ${NODE_NAME}" | sudo tee -a /etc/hosts > /dev/null
  echo "${IP} ${NODE_NAME}" | sudo tee /vagrant/scripts/controlplane_ip.txt > /dev/null

  # Initialize Kubernetes
  sudo kubeadm init --control-plane-endpoint=${NODE_NAME} --apiserver-advertise-address=${IP} --pod-network-cidr=10.10.0.0/16

  # Set up kubeconfig
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Install Calico network plugin
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

  # Generate join command for worker nodes and control plane nodes
  kubeadm token create --print-join-command --ttl 0 | tee /vagrant/scripts/worker_join_command.sh /vagrant/scripts/controlplane_join_command.sh > /dev/null
  sudo sh -c 'sed -i "1s/\$/ --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -n 1)/" /vagrant/scripts/controlplane_join_command.sh'
else
  # Setups for other controlplane node
  sudo sed -i "/${NODE_NAME}/d" /etc/hosts
  IP=$(hostname -I | awk '{print $1}')
  echo "${IP} ${NODE_NAME}" | sudo tee -a /etc/hosts > /dev/null
  sudo tee -a /etc/hosts < /vagrant/scripts/controlplane_ip.txt > /dev/null

  # Join the Kubernetes cluster as a control plane node
  sudo bash /vagrant/scripts/controlplane_join_command.sh
fi

# Set up Kubectl and Kubernetes autocompletion for vagrant user
sudo bash /vagrant/scripts/setup-kubectl.sh
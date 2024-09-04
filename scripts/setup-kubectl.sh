#/bin/bash

echo "Setting up kubeconfig for vagrant user"
# Set up kubeconfig for vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
echo "Kubeconfig setup completed"

# Set up Kubernetes autocompletion for vagrant user
sudo -u vagrant bash -c 'echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc'
sudo -u vagrant bash -c 'echo "alias k=kubectl" >> /home/vagrant/.bashrc'
sudo -u vagrant bash -c 'echo "complete -F __start_kubectl k" >> /home/vagrant/.bashrc'
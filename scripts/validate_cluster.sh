#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found"
    exit
fi

# Check nodes status
kubectl get nodes

# Check pods status in all namespaces
kubectl get pods --all-namespaces

# Check if Calico is running
kubectl get pods -n kube-system | grep calico
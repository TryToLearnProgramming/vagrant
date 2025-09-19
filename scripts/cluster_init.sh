#!/bin/bash

# Script to Initialize the Control Plane
#
# Grab the kubernetes service images
# init the service, specifing the base CIDR 
# copy the kube config to the user directory
# install the WEAVE CNI service
#
# The IP Address for the API_SERVER is the host ip address for the machine
#
WEAVE_PKG=https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
API_SERVER_IP=$(ip a l eth1 | awk '/inet\s/ {print $2}' | cut -d/ -f1)
POD_BASE_CIDR=10.201.0.0 # Base address for pods

echo "k8s Control Plane / Cluster Init"
echo ""
echo "POD_BASE_CIDR: '${POD_BASE_CIDR}'"
echo "API_SERVER_IP: '${API_SERVER_IP}'"
echo ""

# Pull down the Kubernetes images for Control Plane Initialization
echo "⚙️  Pulling k8s Images"
sudo kubeadm config images pull

# Spin up the Control Plane Node (and cluster)
echo "⚙️  Initializing Cluster"
sudo kubeadm init --pod-network-cidr=10.201.0.0/16 --apiserver-advertise-address=192.168.63.11

# Verify that the api server is up and running
echo "🔍 Verify API Server is running"
API_STATE=$(sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -o json --name "kube-apiserver" 2>/dev/null | jq -r '.containers[] | select(.metadata.name == "kube-apiserver") | .state')

if   [ "${API_STATE}" == "CONTAINER_RUNNING" ]; then
    echo "✅ Service 'kube-apiserver' is up and running"
elif [ "${API_STATE}" == "" ]; then
    echo "❌ Service 'kube-apiserver' is NOT running"
    exit 1
else
    echo "❌ Service 'kube-apiserver' is NOT running. State: '${API_STATE}'"
    exit 1
fi

# Copy the k8s admin.conf into the user directory for subsequent use
#
if [ -f /etc/kubernetes/admin.conf ] ; then
  echo "⚙️  Create local '.kube/config'"
  mkdir -p ${HOME}/.kube
  sudo cp -f /etc/kubernetes/admin.conf ${HOME}/.kube/config
  sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
fi

# Install the Weave CNI (Container Network Interface)
echo "⚙️  Install Weave CNI Service"
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml --validate=false

# Verify that weave is running
timeout=60 # 2 minutes = 120 seconds
interval=10 # check every 10 seconds
elapsed=0
while [ ${elapsed} -lt ${timeout} ]; do
    echo -n "🔍 Verify Weave Service running"
    if [ ${elapsed} -gt 0 ]; then
        echo " (trying for $((timeout - elapsed)) more seconds)"
    else
	echo ""
    fi
    weave_count=$(kubectl get pods -n kube-system -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | startswith("weave-net-")) | .metadata.name' | wc -l)

    if [ ${weave_count} -gt 0 ]; then
        break
    fi

  sleep ${interval}
  elapsed=$((elapsed + interval))
done

if   [ ${weave_count} -gt 0 ]; then
    echo "✅ Weave CNI Service is running"
else
    echo "❌ Timed out during check - Weave CNI service is NOT running"
    exit 1
fi


#!/usr/bin/env bash

#
# This is the base machine config for any Kubernetes node,
# Whether a Control Plane or a Worker Node
#
# For purpose-specific configuration, put that work in one of:
#   - provision_cplane.sh
#   - provision_worker.sh
#

# Add Node Host Name / IP Address to /etc/hosts
if [[ -n "${ETC_HOSTS}" ]]; then
  sudo echo "# Added by Vagrant" >> /etc/hosts
  sudo echo "#" >> /etc/hosts
  echo -e "${ETC_HOSTS}" | while read -r hline; do
    sudo echo ${hline} >> /etc/hosts
  done
fi

# Check for Kernel module 'br_netfilter' - Bridge Network Filter
# IF needed, Enable (and persist) Kernel Module br_netfilter
if [ "$(lsmod | grep br_netfilter)" == "" ]; then
    sudo modprobe br_netfilter
    sudo touch /etc/modules-load.d/br_netfilter.conf
    sudo chmod 666 /etc/modules-load.d/br_netfilter.conf
    sudo echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
    sudo chmod 644 /etc/modules-load.d/br_netfilter.conf
fi

# Apt Stuff for Docker Install
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Install Docker and ContainerD as the container management tool
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo ufw disable
sudo swapoff -a
sudo apt update && sudo apt install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt update

# Install the main Kubernetes components
sudo apt install -y ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Configure Containerd Daemon
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|g' /etc/containerd/config.toml
sudo systemctl restart containerd

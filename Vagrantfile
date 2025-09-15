# Configuration parameters
VAGRANT_BASE_OS = "bento/ubuntu-24.04" # "bento/ubuntu-22.04"
PRIVATE_NETWORK = "private_network"    # For Host -> VM and VM <-> VM (within the network)
BASE_CIDR       = "10.201.0.0"         # Base address for pods

# Create list of one or more Control Plane Nodes (but one is sufficient)
CPLANE_NODES = [
  { name: "cplane",  box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.11" }
]

# Create list of one or more worker nodes
# Mindful of the 'name' and 'ip' values for each
WORKER_NODES = [
  { name: "worker1", box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.12" }
]

# Work out the "/etc/hosts" values to get copied in each node (cplanes and workers)
ALL_NODES = CPLANE_NODES + WORKER_NODES
ETC_HOSTS = ALL_NODES.map { |n| "#{n[:ip]} #{n[:name]}" }.join("\n") + "\n"

Vagrant.configure("2") do |config|
  # Define Control Plane Nodes
  CPLANE_NODES.each do |node|
    config.vm.define node[:name] do |cplane|
      cplane.vm.box = node[:box]
      cplane.vm.network node[:network], ip: node[:ip]
      cplane.vm.hostname = node[:name]
      cplane.vm.provider "virtualbox" do |v|
        v.name = node[:name]
        v.memory = 2048
        v.cpus = 2
      end
      cplane.vm.provision "shell",
        env: {
          "ETC_HOSTS"     => ETC_HOSTS,
          "BASE_CIDR"     => BASE_CIDR,
          "API_SERVER_IP" => node[:ip] # API Server is the control plane host itself
        },
        inline: <<-SHELL
        # Add Nodes to /etc/hosts
        sudo echo "# Added by Vagrant" >> /etc/hosts
        sudo echo "#" >> /etc/hosts
        echo -e "${ETC_HOSTS}" | while read -r hline; do
          sudo echo ${hline} >> /etc/hosts
        done

        # Create Cluster Init Script:
        echo "#!/bin/bash"                                                     >  cluster_init.sh
        echo "echo 'Pulling k8s Images'"                                       >> cluster_init.sh
        echo "sudo kubeadm config images pull"                                 >> cluster_init.sh
        echo "echo ''"                                                         >> cluster_init.sh
        echo "echo 'Initializing Cluster'"                                     >> cluster_init.sh
        echo "sudo kubeadm init --pod-network-cidr=${BASE_CIDR}/16 --apiserver-advertise-address=${API_SERVER_IP}" >> cluster_init.sh
        echo "if [ -f /etc/kubernetes/admin.conf ] ; then"                     >> cluster_init.sh
        echo "  echo ''"                                                       >> cluster_init.sh
        echo "  echo 'Create local .kube/config'"                              >> cluster_init.sh
        echo "  mkdir -p \\\${HOME}/.kube"                                     >> cluster_init.sh
        echo "  sudo cp -i /etc/kubernetes/admin.conf \\\${HOME}/.kube/config" >> cluster_init.sh
        echo "  sudo chown \\\$(id -u):\\\$(id -g) \\\${HOME}/.kube/config"    >> cluster_init.sh
        echo "  echo ''"                                                       >> cluster_init.sh
        echo "  echo 'Install Weave'"                                          >> cluster_init.sh
        echo "  kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml" >> cluster_init.sh
        echo "fi"                                                              >> cluster_init.sh
        chmod a+rx cluster_init.sh

        # Show the k8s join command:
        echo "#!/bin/bash"                                     >  join_cmd.sh
        echo "echo 'k8s worker join command (may need sudo):'" >> join_cmd.sh
        echo "echo ''"                                         >> join_cmd.sh
        echo "kubeadm token create --print-join-command"       >> join_cmd.sh
        echo "echo ''"                                         >> join_cmd.sh
        sudo chmod a+rx join_cmd.sh

        # Apt Stuff:
        sudo apt update
        sudo apt install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

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

        # apt-transport-https may be a dummy package; if so, you can skip that package
        sudo apt install -y apt-transport-https ca-certificates curl gpg
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt update
        sudo apt install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
        sudo systemctl enable --now kubelet
        sudo containerd config default | sudo tee /etc/containerd/config.toml
        sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
        sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|g' /etc/containerd/config.toml
        sudo systemctl restart containerd
        SHELL
    end
  end

  # Define Worker Nodes
  WORKER_NODES.each do |node|
    config.vm.define node[:name] do |worker|
      worker.vm.box = node[:box]
      worker.vm.network node[:network], ip: node[:ip]
      worker.vm.hostname = node[:name]
      worker.vm.provider "virtualbox" do |v|
        v.name = node[:name]
        v.memory = 2048
        v.cpus = 2
      end
      worker.vm.provision "shell",
        env: {"ETC_HOSTS" => ETC_HOSTS},
        inline: <<-SHELL
        # Add Nodes to /etc/hosts
        sudo echo "# Added by Vagrant" >> /etc/hosts
        sudo echo "#" >> /etc/hosts
        echo -e "${ETC_HOSTS}" | while read -r hline; do
          sudo echo ${hline} >> /etc/hosts
        done
        # Apt Stuff:
        sudo apt update
        sudo apt install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

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
        # apt-transport-https may be a dummy package; if so, you can skip that package
        sudo apt install -y apt-transport-https ca-certificates curl gpg
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt update
        sudo apt install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
        sudo systemctl enable --now kubelet
        sudo containerd config default | sudo tee /etc/containerd/config.toml
        sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
        sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|g' /etc/containerd/config.toml
        sudo systemctl restart containerd
        SHELL
    end
  end
end

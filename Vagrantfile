Vagrant.configure("2") do |config|
  # Define master VM
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-22.04"
    master.vm.network "private_network", ip: "192.168.63.1"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |v|
      v.name = "master"
      v.memory = 2048
      v.cpus = 2
    end
    master.vm.provision "shell", inline: <<-SHELL
      sudo echo "192.168.63.1 master\n192.168.63.2 worker" >> /etc/hosts
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

  # Define worker VM
  config.vm.define "worker" do |worker|
    worker.vm.box = "bento/ubuntu-22.04"
    worker.vm.network "private_network", ip: "192.168.63.2"
    worker.vm.hostname = "worker"
    worker.vm.provider "virtualbox" do |v|
      v.name = "worker"
      v.memory = 2048
      v.cpus = 2
    end
    worker.vm.provision "shell", inline: <<-SHELL
      sudo echo "192.168.63.1 master\n192.168.63.2 worker" >> /etc/hosts
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

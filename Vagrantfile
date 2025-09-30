# Configuration parameters
VAGRANT_BASE_OS = "bento/ubuntu-24.04"
PRIVATE_NETWORK = "private_network"    # For Host -> VM and VM <-> VM (within the network)

# Create list of one or more Control Plane Nodes (but one is sufficient)
CPLANE_NODES = [
  { name: "cplane",  box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.11" }
]

# Create list of one or more worker nodes
# Mindful of the 'name' and 'ip' values for each
WORKER_NODES = [
  { name: "worker1", box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.12" }
#  { name: "worker1", box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.12" },
#  { name: "worker2", box: VAGRANT_BASE_OS, network: PRIVATE_NETWORK, ip: "192.168.63.13" }
]

# Work out the "/etc/hosts" values to be copied in each node (cplanes and workers)
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
        env: { "ETC_HOSTS" => ETC_HOSTS },
        inline: <<-SHELL
          # Provision the Control Plane (Base and Specific)
          /vagrant/scripts/provision/provision_base.sh
          [ -f "/vagrant/scripts/provision/provision_cplane.sh" ] && /vagrant/scripts/provision/provision_cplane.sh

          cp -f /vagrant/scripts/cplane/*.sh . 2>/dev/null || true
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
          # Provision the Worker (Base and Specific)
          /vagrant/scripts/provision/provision_base.sh
          [ -f "/vagrant/scripts/provision/provision_worker.sh" ] && /vagrant/scripts/provision/provision_worker.sh

          cp -f /vagrant/scripts/worker/*.sh . 2>/dev/null || true
        SHELL
    end
  end
end

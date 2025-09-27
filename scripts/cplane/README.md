# Vagrant Kubernetes Cluster

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

This project sets up a local Kubernetes cluster using Vagrant and VirtualBox. It creates two Ubuntu 24.04 virtual machines: one control plane node and one worker node with automatic installation of Docker, Kubernetes components, and necessary configurations.

## Control Plane Scripts

🛠 These scripts are copied to - and executed on - the Control Plane. They are designed to make it easier to initialize the cluster, and set up some basic things

<table>
<tr>
    <td>🚀&nbsp;cluster_init.sh</td>
    <td>Initialize the Kubernetes Cluster and install the Weave CNI</td>
</tr>
<tr>
    <td>🛠&nbsp;kube_dashboard.sh </td>
    <td>Install the Kubernetes Dashboard</td>
</tr>
<tr>
    <td>⚙️&nbsp;set_worker_role.sh</td>
    <td>Define "worker" labels for each of the worker nodes in the Cluster</td>
</tr>
<tr>
    <td>📜&nbsp;join_cmd.sh</td>
    <td>Show the "join' information to be used on any worker nodes in the Cluster</td>
</tr>
</table>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2024 Vagrant Kubernetes Cluster

## 📫 Support & Contribution

If you encounter any issues or need assistance:

[![Create Issue](https://img.shields.io/badge/Create-Issue-green.svg)](https://github.com/yourusername/vagrant-kubernetes/issues/new)
[![Pull Request](https://img.shields.io/badge/Pull-Request-blue.svg)](https://github.com/yourusername/vagrant-kubernetes/pulls)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ for the Kubernetes community
</div>

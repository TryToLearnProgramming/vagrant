# Vagrant Kubernetes Cluster

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

This project sets up a local Kubernetes cluster using Vagrant and VirtualBox. It creates two Ubuntu 24.04 virtual machines: one control plane node and one worker node with automatic installation of Docker, Kubernetes components, and necessary configurations.

## Bash Scripts

These scripts are to make it easy to bring up and maintain the Kubernetes Cluster.  Some are collections of manual provisioning commands from the original project (which reduces manual typing errors). Others are facilitators, to manage the Control Plane and Worker nodes in an easy and repeatable fashion.

<table>
<tr>
    <td>🚜&nbsp;Provision</td>
    <td>Package Installation and Service Management of Machines</td>
</tr>
<tr>
    <td>🚀&nbsp;Cplane</td>
    <td>To spin up and manage the Control Plane</td>
</tr>
<tr>
    <td>🛠&nbsp;Worker</td>
    <td>To join up and manage the Worker nodes</td>
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

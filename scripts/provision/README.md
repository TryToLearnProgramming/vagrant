# Vagrant Kubernetes Cluster

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

This project sets up a local Kubernetes cluster using Vagrant and VirtualBox. It creates two Ubuntu 24.04 virtual machines: one control plane node and one worker node with automatic installation of Docker, Kubernetes components, and necessary configurations.

## System Provisioning Scripts

🛠 These scripts perform System provisioning and of the Machines (VM or Bare Metal), such as
* Package Repository management (adding new package sources)
* Package installation or upgrade
* Service start / restart

Originally embedded in the project Vagrantfile, the work was separated out into these discrete Bash scripts to provide flexibility and consistency across the nodes.

They are designed to make it easier to have a "baseline" installation of a collection of Kubernetes nodes - Control Plane or Worker - and to use the scripts in future projects outside of Vagrant / VirtualBox; provisioning bare metal machines, for example.

<table>
<tr>
    <td>🚜&nbsp;provision_base.sh</td>
    <td>Install packages and enable services that are on every Kubernetes node, whether Control Plane or Worker node</td>
</tr>
<tr>
    <td>🚜&nbsp;provision_cplane.sh </td>
    <td>Install packages and enable services that are specific to the Control Plane</td>
</tr>
<tr>
    <td>🚜&nbsp;provision_worker.sh</td>
    <td>Install packages and enable services that are specific to the Worker node</td>
</tr>
</table>

## Future Use

These scripts are designed to make it easier to have a "baseline" installation of a collection of Kubernetes nodes - Control Plane or Worker.  While tailored to this Github Project, it is possible (and encouraged) to use the scripts in future projects outside of Vagrant / VirtualBox; provisioning bare metal machines, for example.

### Ubuntu-Specific

While these scripts are written for Ubuntu, future work could include 'provision_base_DISTRO.sh' for provisioning on other Linux Distros (e.g. SUSE, RHEL, CentOS)

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

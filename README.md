# `Storage Backup and Automation`

This repository showcases my expertise as a SAN storage and automation expert. It includes various automation scripts and projects that I have contributed to, focusing on storage health checks, OpenStack and Ceph snapshot backups, API creation using Python and FastAPI, Kubernetes cluster creation scripts, Data Analytics and Ansible basics.

Feel free to explore the contents of this repository and leverage the automation solutions to streamline your storage management and enhance your infrastructure.

## Authors
 - [Prasanna Ram](https://github.com/prasannaram19591/)

## Scripts and Projects

| Project Name | Status
| -------------| ---------- |
| [_`Shell script Basics`_](https://github.com/prasannaram19591/source-code/tree/main/linux_bash_scripts) | ✅ |
| [_`Ansible Basics`_](https://github.com/prasannaram19591/source-code/tree/main/linux_test_ansibles) | ✅ |
| [_`IBM V7000 Health Check`_](https://github.com/prasannaram19591/source-code/tree/main/IBM_V7000_Health_check) | ✅ |
| [_`HP MSA Health Check`_](https://github.com/prasannaram19591/source-code/tree/main/san_nas_switch_health_check) | ✅ |
| [_`Netapp Health Check`_](https://github.com/prasannaram19591/source-code/tree/main/san_nas_switch_health_check) | ✅ |
| [_`Brocade Health Check`_](https://github.com/prasannaram19591/source-code/tree/main/san_nas_switch_health_check) | ✅ |
| [_`Cisco Health Check`_](https://github.com/prasannaram19591/source-code/tree/main/san_nas_switch_health_check) | ✅ |
| [_`FIO Benchmarking scripts`_](https://github.com/prasannaram19591/source-code/tree/main/fio_benchmarking_scripts) | ✅ |
| [_`EMC Unity LUN auto provision`_](https://github.com/prasannaram19591/source-code/tree/main/EMC_Unity_auto_storage_provisioning) | ✅ |
| [_`Openstack & Ceph Backup`_](https://github.com/prasannaram19591/source-code/blob/main/openstack_vm_snap_add_purge_revert/openstack_vm_snap_add_purge_revert.py) | ✅ |
| [_`VMware vm snapshot`_](https://github.com/prasannaram19591/source-code/tree/main/vmware_snapshot_with_esxcli_python) | ✅ |
| [_`API creation`_](https://github.com/prasannaram19591/source-code/tree/main/api) | ✅ |
| [_`Data Analytics`_](https://github.com/prasannaram19591/source-code/tree/main/data_analytics) | ✅ |
| [_`K8S cluster creation`_](https://github.com/prasannaram19591/source-code/tree/main/minikube) | ✍️ |
### Storage Health Check Scripts
This script performs comprehensive health checks on SAN/NAS storage systems, ensuring optimal performance and reliability. It includes checks for disk utilization, RAID configuration, connectivity, and more. Check out 
[_`Storage Health Check Scripts`_](https://github.com/prasannaram19591/source-code/tree/main/san_nas_switch_health_check) for the codes.
### OpenStack and Ceph Snapshot Backup
Automates the creation and management of snapshots for OpenStack instances. It integrates with Ceph for efficient and reliable backup and recovery operations. Checkout the below links for code.

[_`Shell script for openstack backup creation`_](https://github.com/prasannaram19591/source-code/tree/main/ceph_openstack_backup_create_and_delete)
[_`Python script for openstack backup creation and restoration`_](https://github.com/prasannaram19591/source-code/tree/main/openstack_instance_backup_add_delete_using_ceph_backend)
### API Creation using Python and FastAPI
 Demonstrates how to create a RESTful API using Python and FastAPI. It includes examples of CRUD (Create, Read, Update, Delete) operations on SAN storage resources.
[_`API creation using FasiAPI`_](https://github.com/prasannaram19591/source-code/tree/main/api)
### Kubernetes Cluster Creation Scripts
Shell script that automates the creation of a Kubernetes cluster. It sets up the master node, deploys worker nodes, and configures networking, ensuring a smooth and efficient cluster setup process.
[_`Minikube K8S creation`_](https://github.com/prasannaram19591/source-code/tree/main/minikube)
### Ansible Basics
An Ansible playbook that showcases the basics of using Ansible for infrastructure automation. It includes examples of provisioning SAN storage resources, configuring network settings, and deploying applications.
[_`Ansible Basics`_](https://github.com/prasannaram19591/source-code/tree/main/ansible_samples)
### Getting Started
To get started with any of the scripts or projects in this repository, follow these steps:

_1. Clone the repository_
```shell
git clone https://github.com/prasannaram19591/source-code.git
```
_2. Navigate to the project directory_
```shell
cd repository-name
```
_3. Follow the instructions in the respective script or project's documentation to set up any dependencies or requirements_

_4. Execute the script or deploy the project as per your specific use case_
## Contributing
Contributions are always welcome! If you would like to contribute to this repository, please follow these steps:

_1. Fork the repository_

_2. Create a new branch for your feature or bug fix_
```shell
git checkout -b my-feature
```
_3. Make your modifications and commit them with descriptive messages_
```shell
git commit -m "Add feature or fix bug"
```
_4. Push your changes to the branch_
```shell
git push origin my-feature
```
_5. Open a pull request detailing your changes_
## License
All the codes are opensourced. Feel free to use and modify the code as per your requirements.
Happy automating!

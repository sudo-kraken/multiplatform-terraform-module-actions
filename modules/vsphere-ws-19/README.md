# Terraform vSphere Windows Sserver 2019 Module

## Overview

This Terraform module simplifies the deployment of a Windows Server 2019 (WS19) virtual machine in a vSphere environment. It automates various setup tasks, including resource provisioning, network configuration, and software installation, tailored for WS19.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `VSPHERE_PASSWORD` the password for your vCenter user
- GitHub self-hosted runner, provisioned with access to the vCenter appliance (in this case tagged with **devops**)
- Have the Packer WS19 template provisioned in vSphere, from my repo [here](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main/VMware/Windows-2019)

## Module Details

In detail, the module performs the following tasks:

- Retrieves essential information about the vSphere environment using data sources.
- Provisions a WS19 virtual machine with specified configurations.
- Configures post-deployment tasks, including Active Directory (AD) domain join, disk initialisation, DNS settings, and more.
- Provides flexibility for customisations based on your infrastructure requirements.

This module streamlines the deployment and management of WS19 in a vSphere environment.

## Usage

### Initialize vSphere WS19 Workflow

To use this module, follow these steps:

1. Trigger the `Init vSphere WS19 CD` workflow manually from the "Actions" tab in your GitHub repository.

2. Provide the required inputs when prompted:

   - `hostname`: Enter desired hostname, vCenter IP, vCenter User, separated by commas i.e. "windows-box-01,192.168.1.150,admin@domain.local".
   - `vsphere_cluster`: Enter the name of the vSphere cluster to deploy to.
   - `vsphere_folder`: Enter the path of the existing folder to deploy to i.e. "Path/To/VM".
   - `vsphere_datastore`: Enter the vSphere cluster and datastore to deploy to, separated by commas i.e. "DATACENTER1,DATASTORE_NAME"
   - `vsphere_network`: Specify the name of the vSphere port group to connect the WS19 VM.
   - `network_details`: Enter IP address, network subnet CIDR, and network gateway for the port group, separated by commas (e.g., "192.168.1.10,24,192.168.1.1").
   - `dns_servers`: Enter DNS server addresses to be used, separated by commas (e.g., "192.168.1.100,192.168.1.200"). Leave blank to use Cloudflare DNS.
   - `cpu_ram`: Specify the number of CPUs and the amount of RAM (MB) to allocate to the WS22 VM, separated by a comma (e.g., "4,8192").
   - `AD_Details`: Enter ADJoin, ADPass, ADOU, ADUser, and ADDomain, separated by commas (e.g., "true,pass,user,domain.local"). Leave empty if no domain join is required.
   - `vm_disks`: Enter the size of each additional disk to add in GB, separated by commas (e.g., "100,200"). Leave empty if no additional disks are needed.

3. The workflow will generate a `main.tf` file based on the provided inputs, replacing placeholders with actual values.

4. If a new `main.tf` file is created, it will be automatically committed and pushed to the root of your GitHub repository.

Please note that the `main.tf` file generation will only occur if it does not already exist in the repository.

### Execute vSphere WS CD Workflow

To use this workflow, follow these steps:

1. Trigger the `Exec vSphere WS 16/19/22 CICD` workflow manually from the "Actions" tab in your GitHub repository.

2. The workflow will execute the following steps:

   - **Checkout**: This step checks out the repository to the GitHub Actions runner.
   - **Node Setup**: Sets up a Node.js environment with a specific version.
   - **Setup Terraform**: Sets up the Terraform CLI on the runner.
   - **Terraform Init**: Initialises your Terraform working directory.
   - **Terraform Plan**: Generates an execution plan for Terraform to preview the changes.
   - **Terraform Apply**: Applies the changes needed to achieve the desired configuration state using Terraform.

## License

This Terraform module is open-source and available under the GNU General Public License v3.0.

## Authors

[Joe Harrison]

## Support

For questions, issues, or contributions, please open an issue in this repository.

## Disclaimer

This module is intended to simplify the provisioning of WS19 VMs in a vSphere environment. It should be used with care, considering the resources it creates and their associated costs. Review and adjust the configurations to match your specific requirements and security considerations.

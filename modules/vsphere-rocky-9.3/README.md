# Terraform vSphere Rocky Linux 9.3 Module

## Overview

This Terraform module simplifies the deployment of Rocky Linux 9.3 virtual machine(s) in a vSphere environment. It automates various setup tasks, including resource provisioning, network configuration, and software installation, tailored for Rocky Linux 9.3.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `VSPHERE_PASSWORD` the password for your vCenter user
   - `SSH_PASSWORD` the password specified previously when the `ROCKY-9_3-PKR-V1` packer template was created
- GitHub self-hosted runner, provisioned with access to the vCenter appliance (in this case tagged with **devops**)
- Have the Packer Rocky 9.3 template provisioned in vSphere, from my repo [here](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main/VMware/Rocky-9.3)

## Module Details

In detail, the module performs the following tasks:

- Retrieves essential information about the vSphere environment using data sources.
- Provisions a Rocky Linux virtual machine(s) with specified configurations.
- Configures post-deployment tasks, including waiting for cloud-init to complete, copying SSH keys, and running remote-exec commands.
- Provides local variables for calculating the Rocky Linux VMs IP address.

This module streamlines the deployment and management of Rocky Linux in a vSphere environment while providing flexibility for customisation based on your infrastructure requirements.

## Usage

## vSphere Rocky 9.3 CD Workflow
To use this module, follow these steps:

1. Trigger the `vSphere Rocky 9.3 CD` workflow manually from the "Actions" tab in your GitHub repository.

2. Provide the required inputs when prompted:

   - `vsphere_cluster`: Enter the name of the vSphere cluster for deploying the Rocky Linux VM.
   - `hostname`: nter desired hostname and vCenter User, separated by commas, i.e. "rocky-01,user@domain.local".
   - `vsphere_folder`: Enter the name of the existing folder to deploy to i.e. "Path/To/VM.
   - `vsphere_datastore`: Enter the vSphere datacenter and datastore to deploy the rocky host on, separated by commas, i.e. "DATACENTER1,DATASTORE4".
   - `vsphere_network`: Specify the name of the vSphere port group to connect the Rocky Linux VM(s).
   - `deployment_ips`: Enter ip address(s) for the rocky host(s) i.e. "192.168.1.50" or "192.168.1.50,192.168.1.51".
   - `deployment_cidr`: Specify the network subnet CIDR, i.e "22" or "24".
   - `deployment_gateway`: Enter the network gateway, i.e. "192.168.1.1".
   - `deployment_cpu`: Specify the number of CPUs to allocate to the Rocky Linux VM.
   - `deployment_ram`: Enter the amount of RAM to allocate to the Rocky Linux VM in MB.

3. The workflow will generate a `main.tf` file based on the provided inputs, replacing placeholders with actual values.

4. If a new `main.tf` file is created, it will be automatically committed and pushed to the root of your GitHub repository.

>[!IMPORTANT]
>Please note that the `main.tf` file generation will only occur if it does not already exist in the repository.

Once the `main.tf` file is generated and pushed, you can proceed to use Terraform to apply the configuration for your Rocky Linux deployment.

5. The workflow will execute the following steps:

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

This module is intended to simplify the provisioning of a Rocky Linux VM(s) in a vSphere environment. It should be used with care, considering the resources it creates and their associated costs. Review and adjust the configurations to match your specific requirements and security considerations.

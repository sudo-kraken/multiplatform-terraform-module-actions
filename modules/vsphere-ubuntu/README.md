# Terraform vSphere Ubuntu 22.04 Module

## Overview

This Terraform module simplifies the deployment of an Ubuntu 22.04 VM in a vSphere environment. It automates various setup tasks, including SSH key generation, resource provisioning, network configuration, and software installation, tailored for Ubuntu 22.04.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `VSPHERE_PASSWORD` the password for your vCenter user
   - `SSH_PASSWORD` the password specified previously when the `UBNT-2204-PKR-V1` packer template was created
- GitHub self-hosted runner, provisioned with access to the vCenter appliance (in this case tagged with **devops**)
- Have the Packer Ubuntu 22.04 template provisioned in vSphere, from my repo [here](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main/VMware/Ubuntu-22-04)

## Module Details

In detail, the module performs the following tasks:

- Generates SSH key pairs for passwordless authentication.
- Retrieves essential information about the vSphere environment using data sources.
- Provisions an Ubuntu 22.04 virtual machine with specified configurations.
- Configures post-deployment tasks, including waiting for cloud-init to complete, copying SSH keys, and running remote-exec commands.

This module streamlines the deployment and management of an Ubuntu 22.04 VM in a vSphere environment while providing flexibility for customization based on your infrastructure requirements.

## Usage

### Init vSphere Ubuntu 22.04 CD Workflow

To use this module, follow these steps:

1. Trigger the `Init vSphere Ubuntu 22.04 CD` workflow manually from the "Actions" tab in your GitHub repository.

2. Provide the required inputs when prompted:

   - `deployment_name`: Enter the name to give the deployed VM in VMware and the hostname.
   - `vsphere_user`:  Enter the vSphere user i.e. "user@domain.local".
   - `vsphere_datacenter`: Enter the vSphere server IP and Datacenter to use, separated by commas i.e. "192.168.1.100,DATACENTER1".
   - `vsphere_cluster`: Enter the name of the vSphere cluster to deploy to.
   - `vsphere_folder`: Enter the path of the existing folder to deploy to i.e. "Path/To/VM".
   - `vsphere_datastore`: Enter the name of the vSphere datastore to deploy the VM on.
   - `vsphere_network`: Specify the name of the vSphere port group to connect the VM to.
   - `deployment_cpu`: Specify the number of CPUs to allocate to the VM.
   - `deployment_ram`: Enter the amount of RAM to allocate to the VM in MB.
   - `deployment_network_info`: Enter the IP address, subnet cidr, and default gateway for the VM, separated by commas i.e. "192.168.1.200,24,192.168.1.1".   

3. The workflow will generate a `main.tf` file based on the provided inputs, replacing placeholders with actual values.

4. If a new `main.tf` file is created, it will be automatically committed and pushed to the root of your GitHub repository.

Please note that the `main.tf` file generation will only occur if it does not already exist in the repository.

Once the `main.tf` file is generated and pushed, you can proceed to use Terraform to apply the configuration for your Center Stage deployment.

### Execute vSphere Ubuntu 22.04 CD Workflow

To use this workflow, follow these steps:

1. Trigger the `Exec vSphere Ubuntu 22.04 CD` workflow manually from the "Actions" tab in your GitHub repository.

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

This module is intended to simplify the provisioning of an Ubuntu 22.04 VM in a vSphere environment. It should be used with care, considering the resources it creates and their associated costs. Review and adjust the configurations to match your specific requirements and security considerations.

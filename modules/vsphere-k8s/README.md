# Terraform Kubernetes (k8s) Cluster Module for VMware

## Overview
This Terraform module enables the provisioning of a Kubernetes (k8s) cluster on VMware infrastructure along with a management node to connect with the cluster directly in the within the same network. It automates the setup of essential components, including virtual machines (VMs) for Kubernetes nodes, networking configurations, and any necessary dependencies. The module supports the creation of Kubernetes worker node groups with various configurations.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `VSPHERE_PASSWORD` the password for your vCenter user
   - `SSH_PASSWORD` the password specified previously when the `ROCKY-9_3-PKR-V1` packer template was created
- GitHub self-hosted runner, provisioned with access to the vCenter appliance (in this case tagged with **devops**)
- Have the Packer Rocky 9.3 template provisioned in vSphere, from my repo [here](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main/VMware/Rocky-9.3)

## Module Details

In detail, the module performs the following tasks:

   - Creates virtual machines (VMs) for Kubernetes nodes, including control plane and worker nodes.
   - Configures networking, including virtual networks, subnets, and load balancers, to support the Kubernetes cluster.
   - Sets up any necessary dependencies, such as storage and DNS configurations.
   - Offers flexibility in defining node pools (worker node groups) with varying configurations, allowing customisation of VM sizes, scaling, and labeling.
   - Automatically generates user data scripts for worker nodes, simplifying the bootstrap process within the Kubernetes cluster.

This module streamlines the setup and management of your Kubernetes cluster on VMware while providing the flexibility to adapt to your specific infrastructure requirements.

## Usage

### vSphere K8S CD Workflow
To use this module, follow these steps:

1. Trigger the `vSphere K8S CD` workflow manually from the "Actions" tab in the GitHub repository.

2. Provide the following inputs when prompted:

   - `vsphere_server` : Enter the vSphere Server IP, User, Datacenter, Cluster to deploy the K8S on, separated by commas, i.e. "192.168.1.100,user@domain.local,DATACENTER1,CLUSTER4".
   - `vsphere_stack` : Enter stack shorthand name and folder path to deploy to i.e."pe,PATH/TO/K8S Cluster" this is for a Production Environment into a K8S Cluster folder
   - `vsphere_datastore` : Specify the name of the vSphere datastore where the Kubernetes cluster's VM files should be stored.
   - `vsphere_network` : Define the name of the vSphere virtual network to which the Kubernetes cluster will be connected.
   - `deployment_ip` : Enter ip address for the admin host 10.0.10.150, node ips follow this sequentially.
   - `deployment_cidr` : Enter network subnet cidr i.e. /22 or /24 with "/".
   - `deployment_gateway` : Enter network gateway cidr i.e. 10.0.10.1'.
   - `number_of_nodes` : Specify the total number of nodes to deploy, including both masters and workers.
   - `deployment_cpu` : Choose the number of CPUs to allocate to the Kubernetes VMs. Options include 4, 8, 16, and 32.
   - `deployment_ram` : Select the amount of RAM, in MB, to allocate to the Kubernetes VMs. Options include 8192, 16384, 32768, and 65536.

4. The workflow will generate Terraform configuration files based on the provided inputs and replace placeholders with actual values.

5. If new Terraform configuration files were created, they will be automatically committed and pushed to the GitHub repository root.

> [!IMPORTANT]  
> The workflow will only generate configuration files if they do not already exist in the repository.

Once the configuration files are generated and pushed, it will then proceed with using Terraform to apply the configuration for your Kubernetes cluster on VMware.

6. The workflow will execute the following steps:

   - **Checkout**: This step checks out the repository to the GitHub Actions runner.
   - **Node Setup**: Sets up a Node.js environment with a specific version.
   - **Setup Terraform**: Sets up the Terraform CLI on the runner.
   - **Terraform Init**: Initialises your Terraform working directory.
   - **Terraform Plan**: Generates an execution plan for Terraform to preview the changes.
   - **Terraform Apply**: Applies the changes needed to achieve the desired configuration state using Terraform.
   - **Check SSH Key Existence**: Checks if SSH key files exist in the root of the repository.
   - **Commit and Push SSH Keys**: If new SSH key files were created, this step commits and pushes them to the repository.

## Outputs

- **private-key** (string): The contents of the generated private key.
  - *Description*: The contents of the generated private key.
  - *Value*: `module.private_key_output.stdout`

- **public-key** (string): The contents of the generated public key.
  - *Description*: The contents of the generated public key.
  - *Value*: `module.public_key_output.stdout`

- **k8s-admin-node-ip** (string): The IP address of the admin node in the Kubernetes cluster.
  - *Description*: The IP address of the admin node.
  - *Value*: `local.admin_node_ip`

- **k8s-node-ips** (list): The IP addresses of all nodes in the Kubernetes cluster.
  - *Description*: The IP addresses of all nodes.
  - *Value*: `local.node_ips`

## License

This Terraform module is open-source and available under the GNU General Public License v3.0.

## Authors

[Joe Harrison]

## Support

For questions, issues, or contributions, please open an issue.

## Disclaimer

This module is intended to simplify the provisioning of a Kubernetes cluster on vSphere infrastructure, but it should be used with care. Ensure that you understand the resources it creates and their associated configurations. Review and adjust the configurations to match your specific requirements and infrastructure considerations.

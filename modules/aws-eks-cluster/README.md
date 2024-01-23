# Terraform AWS EKS Cluster Module

## Overview

This Terraform module enables the provisioning of an Amazon Elastic Kubernetes Service (EKS) cluster on AWS. It automates the setup of essential components, including KMS keys for encryption, an S3 bucket for storing Terraform state files, IAM roles for the cluster and worker nodes, and security groups. The module also supports the creation of EKS worker node groups with various configurations.

A Windows EC2 Jump box will also be provisioned for post deployment access.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `AWS_ACCESS_KEY` the AWS account Access Key you will use to setup the AWS Cli on the GitHub Runner
   - `AWS_SECRET_KEY` the AWS account Secret Key you will use to setup the AWS Cli on the GitHub Rcreated
- Your AWS Account must have all the necessary IAM role permissions to be able to use AWS S3, VPC's, KMS, DynamoDB etc, please refer to the AWS IAM Example Role in the repo
- An S3 bucket created named `global-gh-tf-state` to store your terraform statefiles and the main.tf file used in this deployment
- A KMS key used to encrypt the files within the terraform bucket, you will need to edit the `.github/workflows/exec-aws-eks-deployment.yml` file on line **74** to replace the key arn with your own here
- OPTIONALLY - Edit the regions in `.github/workflows/init-tf-aws-eks.yml` and  `.github/workflows/exec-aws-eks-deployment.yml`
    - Line **107** in the init file and lines **62**, **75** in the exec file
- OPTIONALLY - Edit the instance types used in in `.github/workflows/init-tf-aws-eks.yml`
    - Lines **157**, it is currently set to use `m5a.2xlarge`

## Module Details

In detail, the module performs the following tasks:

   - Creates a KMS key for encryption.
   - Sets up an S3 bucket for storing Terraform state files.
   - Creates a DynamoDB table for state locking.
   - Configures IAM roles for the EKS cluster and worker nodes.
   - Establishes security groups for the EKS cluster and worker nodes, ensuring the necessary network permissions.
   - Offers flexibility in defining node pools (worker node groups) with varying configurations, allowing customization of instance types, scaling, and labeling.
   - Allows you to specify EKS add-ons such as the VPC CNI to enhance the cluster's functionality.
   - Automatically generates user data scripts for worker nodes, simplifying the bootstrap process within the EKS cluster.
   - Creates an EC2 `t3a.large` instance and configures it with access to the cluster as a jump box.

This module streamlines the setup and management of your EKS cluster on AWS while providing the flexibility to adapt to your specific infrastructure requirements.

## Usage

## Init AWS EKS Workflow
To use this module, follow these steps:

1. Trigger the `Init AWS EKS` workflow manually from the "Actions" tab in the GitHub repository.

2. Provide the following inputs when prompted:

   - `cluster_name`: Enter a name for the cluster.
   - `vpc_id`: Enter the VPC ID i.e. "vpc-00000000000000001".
   - `service_cidr`: Enter the internal EKS service cidr to use within the cluster i.e. 10.200.0.0/16.
   - `vpc_subnet_ids`: Enter 2 private subnet IDs, comma-separated i.e. "subnet-00000000000000001,subnet-00000000000000002".
   - `vpc_public_subnet_id`: Enter the public subnet id to deploy the jumpbox in i.e. "subnet-00000000000000001".
   - `capacity_type`: Enter the provisioning type to be used (all uppercase) i.e. "SPOT" or "ON_DEMAND".
   - `client_tag`: Enter the value to be used in the client tag (all lowercase) i.e. "client1" or "shared".
   - `product_tag`: Enter the value to be used in the product tag (all lowercase) i.e. "client1" or "shared".
   - `environment_tag`: Enter the value to be used in the env tag (all lowercase) i.e. "prod" or "dev".

3. The workflow will generate a main.tf file based on the provided inputs and replace placeholders with actual values.

4. If a new main.tf file was created, it will be automatically committed and pushed to the GitHub repository root.

Note: The workflow will only generate a main.tf file if it does not already exist in the repository.

Once the main.tf file is generated and pushed, you can proceed with using Terraform to apply the configuration for your EKS cluster.

## Execute AWS EKS CICD Workflow

### Workflow Inputs

This workflow expects the following input:

- `eks_cluster`: Enter the EKS cluster name, which should match the name previously entered during the main.tf generation.

### Workflow Execution

To use this workflow, follow these steps:

1. Trigger the `Exec AWS EKS CD` workflow manually from the "Actions" tab in the GitHub repository.

2. The workflow will execute the following steps:

   - **Checkout** : This step checks out the repository to the GitHub Actions runner.
   - **Node Setup** : Sets up a Node.js environment with a specific version.
   - **Set up AWS CLI** : Configures AWS CLI credentials for authentication.
   - **Setup Terraform** : Sets up the Terraform CLI on the runner.
   - **Terraform Init** : Initialises your Terraform working directory.
   - **Terraform Plan** : Generates an execution plan for Terraform to preview the changes.
   - **Terraform Apply** : Applies the changes needed to achieve the desired configuration state using Terraform.
   - **S3 Upload**: Upload Terraorm Statefiles and main.tf to S3   

## Outputs

- **eks_cluster_name** (string): The name of the EKS cluster.
  - *Description*: The name of the EKS cluster.
  - *Value*: `aws_eks_cluster.eks_cluster.name`

- **eks_cluster_endpoint** (string): The endpoint for the EKS cluster's Kubernetes API server.
  - *Description*: The endpoint for the EKS cluster.
  - *Value*: `aws_eks_cluster.eks_cluster.endpoint`

- **eks_cluster_arn** (string): The ARN of the EKS cluster.
  - *Description*: The ARN of the EKS cluster.
  - *Value*: `aws_eks_cluster.eks_cluster.arn`

- **eks_cluster_version** (string): The Kubernetes version of the EKS cluster.
  - *Description*: The Kubernetes version of the EKS cluster.
  - *Value*: `aws_eks_cluster.eks_cluster.version`

- **eks_worker_nodes_security_group_id** (string): The ID of the security group for the worker nodes.
  - *Description*: The ID of the security group for the worker nodes.
  - *Value*: `aws_security_group.eks_worker_nodes_sg.id`

- **eks_cluster_security_group_id** (string): The ID of the security group for the EKS cluster.
  - *Description*: The ID of the security group for the EKS cluster.
  - *Value*: `aws_security_group.eks_cluster_sg.id`

- **eks_cluster_kms_key_arn** (string): The ARN of the KMS key used for secret encryption in the EKS cluster.
  - *Description*: The ARN of the KMS key used for secret encryption in the EKS cluster.
  - *Value*: `aws_kms_key.eks.arn`
  
## License

This Terraform module is open-source and available under the GNU General Public License v3.0.

## Authors

[Joe Harrison]

## Support

For questions, issues, or contributions, please open an issue.

## Disclaimer

This module is intended to simplify the provisioning of an EKS cluster on AWS, but it should be used with care. Ensure that you understand the resources it creates and their associated costs. Review and adjust the configurations to match your specific requirements and security considerations.

# Terraform AWS VPC Module Readme

## Overview

This Terraform module automates the provisioning of an Amazon Web Services (AWS) Virtual Private Cloud (VPC). The module creates a VPC with essential components, including public and private subnets, internet gateway, NAT gateway, and route tables. It streamlines the setup of a VPC while providing the flexibility to customize subnet configurations and tags.

## Prerequisites
- GitHub Secrets have been set for the following values
   - `AWS_ACCESS_KEY` the AWS account Access Key you will use to setup the AWS Cli on the GitHub Runner
   - `AWS_SECRET_KEY` the AWS account Secret Key you will use to setup the AWS Cli on the GitHub Rcreated
- Your AWS Account must have all the necessary IAM role permissions to be able to use AWS S3, VPC's, KMS, DynamoDB etc, please refer to the AWS IAM Example Role in the repo
- An S3 bucket created named `global-gh-tf-state` to store your terraform statefiles and the main.tf file used in this deployment
- A KMS key used to encrypt the files within the terraform bucket, you will need to edit the `.github/workflows/exec-aws-vpc-deployment.yml` file on line **74** to replace the key arn with your own here
- OPTIONALLY - Edit the regions in `.github/workflows/init-tf-aws-vpc.yml` and  `.github/workflows/exec-aws-vpc-deployment.yml`
    - Lines **93**, **99**, **106** in the init file and lines **62**, **75** in the exec file

## Module Details

In detail, the module performs the following tasks:

- Creates a VPC with user-defined CIDR block.
- Configures public and private subnets with customizable CIDR blocks and availability zones.
- Sets up an Internet Gateway (IGW) and attaches it to the VPC for public subnet internet access.
- Allocates an Elastic IP (EIP) for the NAT Gateway used by private subnets.
- Creates a NAT Gateway and associates it with public subnet(s) to enable outbound internet access for private instances.
- Defines public and private route tables with appropriate routes.
- Associates public route table with public subnets and private route table with private subnets.
- Tags resources for better organisation and management.
- Optionally allows you to add additional tags if the VPC is to be used to deploy EKS.
- Stores and encrypts the Terraform state files and main.tf file used to call the module in an AWS S3 bucket.

> [!NOTE]  
> This will create generic access rules to allow ingress and egress for all services to aid in the setup process, once you have completed all initial setup tasks, you should manually remove and add additional security rules to make your deployment more secure.

This module simplifies the creation of AWS VPCs while allowing users to tailor network configurations to their specific needs.

## Usage

## Init AWS VPC CD Workflow
To use this module, follow these steps:

1. Trigger the `Init AWS VPC CD` workflow manually from the "Actions" tab in the GitHub repository.

2. Provide the following inputs when prompted:

   - `vpc_name`: Enter a name for the VPC (in lowercase).
   - `is_eks_enabled`: Is this VPC going to be used to run EKS.
   - `vpc_subnet`: Enter the VPC CIDR block (e.g., "10.0.0.0/16").
   - `vpc_pub_subnets`: Enter 3 public subnet CIDR blocks, comma-separated (e.g., "10.0.1.0/24,10.0.2.0/24,10.0.3.0/24").
   - `vpc_priv_subnets`: Enter 3 private subnet CIDR blocks, comma-separated (e.g., "10.0.10.0/24,10.0.11.0/24,10.0.12.0/24").
   - `client_tag`: Enter the client tag value (in lowercase) i.e. "client1" or "shared".
   - `environment_tag`: Enter the environment tag value (in lowercase) i.e. "prod" or "dev".

3. The workflow will generate a `main.tf` file based on the provided inputs and replace placeholders with actual values.

4. If a new `main.tf` file was created, it will be automatically committed and pushed to the GitHub repository root.

Note: The workflow will only generate a `main.tf` file if it does not already exist in the repository.

Once the `main.tf` file is generated and pushed, you can proceed with using Terraform to apply the configuration for your AWS VPC.

## Execute AWS VPC CD Workflow

### Workflow Execution

To use this workflow, follow these steps:

1. Trigger the `Exec AWS VPC CD` workflow manually from the "Actions" tab in the GitHub repository.

2. The workflow will execute the following steps:

   - **Checkout** : This step checks out the repository to the GitHub Actions runner.
   - **Node Setup** : Sets up a Node.js environment with a specific version.
   - **Setup Terraform** : Sets up the Terraform CLI on the runner.
   - **Terraform Init** : Initialises your Terraform working directory.
   - **Terraform Plan** : Generates an execution plan for Terraform to preview the changes.
   - **Terraform Apply** : Applies the changes needed to achieve the desired configuration state using Terraform.
   - **S3 Upload**: Upload Terraorm Statefiles and main.tf to S3

## License

This Terraform module is open-source and available under the GNU General Public License v3.0.

## Authors

[Joe Harrison]

## Support

For questions, issues, or contributions, please open an issue.

## Disclaimer

This module is intended to simplify the provisioning of an AWS VPC, but it should be used with care. Ensure that you understand the resources it creates and their associated costs. Review and adjust the configurations to match your specific requirements and security considerations.

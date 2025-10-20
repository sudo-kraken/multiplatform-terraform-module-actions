<div align="center">
<img src="docs/assets/logo.png" align="center" width="144px" height="144px"/>

### Multiplatform Terraform Module Actions

_Terraform modules with ready-to-run GitHub Actions workflows for provisioning across AWS and VMware vSphere._
</div>

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-Required-623CE4?logo=terraform&logoColor=white&style=for-the-badge)](https://www.terraform.io/)
[![Terraform Version](https://img.shields.io/badge/Terraform-1.6%2B-623CE4?logo=terraform&logoColor=white&style=for-the-badge)](https://www.terraform.io/)

</div>

<div align="center">

[![OpenSSF Scorecard](https://img.shields.io/ossf-scorecard/github.com/sudo-kraken/multiplatform-terraform-module-actions?label=openssf%20scorecard&style=for-the-badge)](https://scorecard.dev/viewer/?uri=github.com/sudo-kraken/multiplatform-terraform-module-actions)

</div>

## Contents

- [Overview](#overview)
- [Architecture at a glance](#architecture-at-a-glance)
- [Features](#features)
- [Deploying a Virtual Machine using Terraform](#deploying-a-virtual-machine-using-terraform)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Repository structure](#repository-structure)
- [Integration with the Packer repository vSphere modules only](#integration-with-the-packer-repository-vsphere-modules-only)
- [Executing the IAC Actions](#executing-the-iac-actions)
- [Secrets and inputs](#secrets-and-inputs)
- [Troubleshooting](#troubleshooting)
- [Licence](#licence)
- [Security](#security)
- [Contributing](#contributing)
- [Support](#support)

## Overview

This repository is the second part of an infrastructure as code pipeline and uses Terraform to deploy virtual machines and other resources. It works alongside the companion [Packer for vSphere repository](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main), which builds VM templates consumed by the vSphere modules here. There are also modules that do not rely on Packer, including AWS modules for VPCs and EKS.

> [!NOTE]  
> Inside you will find multiple Terraform modules that provision and customise resources across providers such as AWS and VMware. Each module includes its own README with usage and prerequisites. Read the per-module README before running any workflow.

## Architecture at a glance

- Terraform modules for AWS and VMware vSphere
- GitHub Actions workflows that compose a `main.tf` dynamically and run Terraform on a runner
- Provider credentials and variables supplied via repository or organisation secrets
- Optional integration with Packer-built vSphere templates

## Features

- Opinionated modules for common patterns such as AWS VPC and EKS, and vSphere VM deployment from templates
- Workflows that:
  - generate a tailored `main.tf` to wire the chosen module
  - run `terraform init`, `plan` and `apply` on a GitHub runner
- Inputs and secrets driven configuration to avoid hard-coding credentials
- Modular layout encouraging reuse across environments

## Deploying a Virtual Machine using Terraform

Use one of the vSphere modules to deploy a VM from a Packer template and customise it. The provided Actions keep Terraform execution inside CI on a GitHub runner.

## Prerequisites

- Platform prerequisites prepared in advance  
  - **VMware**: VLANs or networks, folders, resource pools and required permissions  
  - **AWS**: IAM permissions, regions and any prerequisite networking if not created by the module
- A copy of this repository in your GitHub account with Actions enabled
- Access to required repository or organisation secrets
- Familiarity with this repository’s structure and the module you plan to run
- To clone with the CLI:
  ```bash
  git clone https://github.com/sudo-kraken/multiplatform-terraform-module-actions.git
  ```

## Quick start

1. Fork or clone this repository.
2. Review the README in the target module under `modules/`.
3. Configure the necessary secrets in your repository or organisation.
4. From the Actions tab, choose the workflow for your target module and run it with the required inputs.

## Repository structure

```
.
├── .github/                 # GitHub Actions workflows
├── modules/                 # Terraform modules by provider or purpose
├── .devcontainer/           # Optional devcontainer setup
├── .vscode/                 # Editor settings
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md
```

## Integration with the Packer repository vSphere modules only

The vSphere modules expect VM templates produced by the companion Packer repository. Build and publish up-to-date templates to vSphere before running VM deployment modules here.

## Executing the IAC Actions

The workflows generate a custom `main.tf` for the selected module and execute Terraform. In summary they:

1. Generate a `main.tf` that wires provider configuration and the chosen module with your inputs.
2. Execute `terraform init` and `terraform apply` to provision the infrastructure.

> [!NOTE]
> Provide the required input variables and credentials such as cloud access keys or vSphere credentials, otherwise the run will fail. See each module’s README for exact variables.

## Secrets and inputs

Typical secrets and inputs:

- **AWS**
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
- **vSphere**
  - `VSPHERE_SERVER`
  - `VSPHERE_USER`
  - `VSPHERE_PASSWORD`
  - Module inputs for datacentre, cluster, datastore and network names

Names and scopes can vary by module. Always refer to the module README for authoritative details.

## Troubleshooting

- **Plan or apply fails early**  
  Check that required secrets are present and correctly scoped. Verify IAM or vSphere permissions.
- **Template not found**  
  For vSphere, ensure the Packer-built template exists and is accessible to the account used by Terraform.
- **Input validation errors**  
  Re-run the workflow and confirm inputs match the module’s variable names and types.

## Licence

This project is licensed under the MIT Licence. See the [LICENCE](LICENCE) file for details.

## Security

If you discover a security issue, please review and follow the guidance in [SECURITY.md](SECURITY.md), or open a private security-focused issue with minimal details and request a secure contact channel.

## Contributing

Feel free to open issues or submit pull requests if you have suggestions or improvements.  
See [CONTRIBUTING.md](CONTRIBUTING.md)

## Support

Open an [issue](/../../issues) with as much detail as possible, including the target platform, the module you used and any workflow logs that help reproduce the problem.

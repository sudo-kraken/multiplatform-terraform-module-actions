<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&width=435&lines=Terraform+Modules+for+GitHub+Actions" alt="Typing SVG"/>
</p>

<p align="center">
  <img src="https://media.giphy.com/media/hvRJCLFzcasrR4ia7z/giphy.gif" width="50" alt="Repo Languages and Tools"/>
</p>

<h1 align="center">Repo Languages and Tools</h1>
 
<p align="center">
  <a href="https://www.terraform.io/"><img src="https://img.shields.io/badge/-Terraform-623CE4?style=flat&logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://www.ansible.com/"><img src="https://img.shields.io/badge/Ansible-%231A1918.svg?style=flat&logo=ansible&logoColor=white" alt="Ansible" /></a>
  <a href="https://git-scm.com/"><img src="https://img.shields.io/badge/-Git-F05032?style=flat&logo=git&logoColor=white" alt="Git" /></a>
  <a href="https://github.com/features/actions"><img src="https://img.shields.io/badge/-GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white" alt="GitHub Actions" /></a>
  <a href="https://www.linux.org/"><img src="https://img.shields.io/badge/-Linux-FCC624?style=flat&logo=linux&logoColor=black" alt="Linux" /></a>
  <a href="https://kubernetes.io/"><img src="https://img.shields.io/badge/-Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white" alt="Kubernetes" /></a>
  <a href="https://aws.amazon.com/"><img src="https://img.shields.io/badge/-AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white" alt="AWS" /></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/-Docker-2496ED?style=flat&logo=docker&logoColor=white" alt="Docker" /></a>
  <a href="https://www.nginx.com/"><img src="https://img.shields.io/badge/-Nginx-009639?style=flat&logo=nginx&logoColor=white" alt="Nginx" /></a>
  <a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/-Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white" alt="Bash" /></a>
  <a href="https://docs.microsoft.com/en-us/powershell/"><img src="https://img.shields.io/badge/-PowerShell-5391FE?style=flat&logo=powershell&logoColor=white" alt="PowerShell" /></a>
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/-Python-3776AB?style=flat&logo=python&logoColor=white" alt="Python" /></a>
  <a href="https://grafana.com/"><img src="https://img.shields.io/badge/-Grafana-F46800?style=flat&logo=grafana&logoColor=white" alt="Grafana" /></a>
  <a href="https://prometheus.io/"><img src="https://img.shields.io/badge/-Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white" alt="Prometheus" /></a>
</p>

<br>
<p align="center">
  <a href="https://www.buymeacoffee.com/jharrison94" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60px" width="217px" >
      
## Overview
This repository, is the second part of my infrastructure-as-code (IAC) pipeline, it leverages Terraform to deploy virtual machines and other resources. It's designed to work in tandem with my other [repository](https://github.com/sudo-kraken/multiplatform-packer-vsphere-actions/tree/main), which uses Packer in vSphere to create the necessary templates for these deployments. There are additional modules here which do not utilise the other repo such as the AWS modules for VPC's and EKS.

> [!NOTE]  
> Within this repo, you'll find multiple Terraform modules capable of provisioning and customising a variety of resources across different providers such as AWS and VMware. Each module is accompanied by its own README, providing detailed instructions and prerequisites. It's crucial to read these READMEs thoroughly before proceeding with any deployment.

## Deploying a Virtual Machine using Terraform
This section guides you through deploying a VM using one of our Terraform modules, executed via a GitHub runner - a critical component for running Terraform in a GitHub Action.

## Prerequisites
Before diving into deployment, ensure you have:
  - Configured the necessary infrastructure elements (VLANs for VMware, VPC's, IAM roles etc. for AWS).
  - Cloned this repository to your GitHub account, renaming it appropriately.
  - Secured access to the organisation-level GitHub secrets if using this within a GitHub org.
  - Familiarised yourself with the repository's structure and content.
  - To clone the GitHub repository using the CLI use following command:
    ```code
        $ git clone https://github.com/sudo-kraken/multiplatform-terraform-module-actions.git
    ```

## Integration with my Packer Repository (vSphere Modules Only)
My Terraform vSphere-based modules are designed to use VM templates created by my Packer repository. Make sure you have the latest templates from the Packer repo, as they're essential for the VM deployment process.

## Generating main.tf File
Initiate one of the `Init` actions in this repository to generate a custom `main.tf` file at the root of the repository. This file is pivotal for your deployment configuration.

## Deployment
After setting up your main.tf via one of the `init` actions:
  - Execute the corresponding `Exec` action. This triggers the deployment process using the configuration specified in `main.tf`.
  - Monitor the deployment progress via the Actions tab in the GitHub repository.
  - Upon completion, access and manage your new VM or resource.

## Define variables for vSphere and deployment configurations
## Author Joe Harrison

# vSphere server hostname or IP address
variable "vsphere_server" {
  description = "vsphere_server"
}
# Name of the vSphere datacenter
variable "vsphere_datacenter" {
  description = "vsphere datacenter name"
}
# Name of the vSphere datastore to use for the VM
variable "vsphere_datasource" {
  description = "vsphere_datasource"
}
# Name of the vSphere cluster to use for the VM
variable "vsphere_cluster" {
  description = "vsphere_cluster"
}
# Name of the vSphere network to use for the VM
variable "vsphere_network" {
  description = "vsphere_network"
}
# Name of the vSphere template to use for the VM
variable "vsphere_template" {
  description = "vsphere_template"
}
# Name to give to the deployed virtual machine in VMware
variable "deployment_name" {
  description = "deployment_name"
}

# Domain name for the virtual machine
variable "deployment_domain" { description = "deployment_domain" }

# IP address to assign to the virtual machine
variable "deployment_ip" { description = "deployment_ip" }

# Subnet to assign to the virtual machine
variable "deployment_subnet" { description = "deployment_subnet" }

# Gateway for the virtual machine
variable "deployment_gateway" { description = "deployment_gateway" }

# A list of DNS server IP addresses
variable "dns_server_list" { 
  type = list(string)
  default = [ ]
}
# A list of DNS suffixes
variable "dns_suffix_list" { 
  type = list(string)
  default = [ ]
}
# Username for logging into the virtual machine
variable "deployment_user" { }

# Password for logging into the virtual machine
variable "deployment_password" {}

# Number of CPUs to allocate to the virtual machine
variable "deployment_cpu" { default=1 }

# Amount of memory to allocate to the virtual machine (in MB)
variable "deployment_ram_mb" { default=1024 }

# Size of the virtual machine's system disk (in GB)
variable "deployment_disk_gb" { default=30 }

# Name of the folder to create the VM in (if it does not already exist)
variable "deployment_vm_folder" { default = "Terraform" }

# A list of additional disks to add and mount for the VM
variable "deployment_additional_disks" {
  description = "A list of additional disks to add and mount for the VM, id should incrememnt from 1, dev e.g. /dev/sdb, lvm 0 for false 1 for true, size in GB and mount location e.g. /mnt/DATA-DRIVE"
  type = list(object({
    id      = number
    dev     = string
    lvm     = number
    sizeGB  = number
    dir     = string
  }))
  default = []
}

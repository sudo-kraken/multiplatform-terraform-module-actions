## This is the main Terraform configuration file for the module vsphere-cs-terraform
## Author Joe Harrison

# Define local variables for disks and disk formatting arguments.
locals {
  disks = var.deployment_additional_disks != [] ? var.deployment_additional_disks : []
  disk_format_args = join(" ", [for disk in local.disks: "${disk.dev},${disk.lvm},${disk.sizeGB},${disk.dir}"] )
}

# Retrieve information about the vSphere datacenter, datastore, compute cluster, host, and network.
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datasource
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_compute_cluster" "cluster" {
  count         = var.vsphere_cluster=="" ? 0:1
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "esxihost" {
  count         = var.vsphere_cluster=="" ? 1:0
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  # Delete VM before recreating 
  lifecycle {
    create_before_destroy = false
  }
  # Define the name of the VM to be created
  name = var.deployment_name
  
  # Specify the resource pool ID based on whether a cluster is used or not
  resource_pool_id = var.vsphere_cluster=="" ? data.vsphere_host.esxihost[0].resource_pool_id:data.vsphere_compute_cluster.cluster[0].resource_pool_id
  
  # Specify the datastore ID
  datastore_id = data.vsphere_datastore.datastore.id
  
  # Specify the folder to create the VM in
  folder = var.deployment_vm_folder
  
  # Specify the number of CPUs, RAM and guest ID for the VM
  num_cpus = var.deployment_cpu
  memory = var.deployment_ram_mb
  guest_id = data.vsphere_virtual_machine.template.guest_id
  
  # Specify the SCSI type for the VM
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  # Define the network interface for the VM
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  
  # Define the primary OS disk for the VM
  disk {
     label            = "osdrive"
     unit_number      = 0
     size             = data.vsphere_virtual_machine.template.disks.0.size
     eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  
  # Define the CD-ROM drive for the VM
  cdrom { 
    client_device = true
  }

  # Create additional disks based on the number of disks specified in the input variables
  dynamic "disk" {
    for_each = [ for disk in local.disks: disk ]
    
    content {
     label            = "disk${disk.value.id}"
     unit_number      = disk.value.id
     datastore_id     = data.vsphere_datastore.datastore.id
     size             = disk.value.sizeGB
     eagerly_scrub    = false
     thin_provisioned = true
    }
  }

  # Clone the VM from the specified template and customize its settings
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.deployment_name
        domain    = var.deployment_domain
      }

      network_interface {
        ipv4_address = var.deployment_ip
        ipv4_netmask = var.deployment_subnet
      }

      ipv4_gateway = var.deployment_gateway
      dns_server_list = var.dns_server_list
      dns_suffix_list = var.dns_suffix_list
    }
  }
  
  # Define the connection type, agent, host, user and password for the VM
  connection {
    type = "ssh"
    agent = "false"
    host = var.deployment_ip
    user = var.deployment_user
    password = var.deployment_password
  }

  # Create a script from the template and copy it to the VM
  provisioner "file" {
    destination = "/tmp/disk_filesystem.sh"
    content = templatefile(
      "${path.module}/scripts/disk_filesystem.sh.tpl",
      { 
        "disks": local.disks
        "default_args" : local.disk_format_args
      }
    )
  }
  
  # Run the script on the VM to create partition and filesystem for data disks
    
  provisioner "remote-exec" {
    inline = [
      "echo ${var.deployment_password} | sudo -S hostnamectl set-hostname ${var.deployment_name}",
      "sudo chmod +x /tmp/disk_filesystem.sh",
      "sudo touch /etc/cloud/cloud-init.disabled",
      "echo ${var.deployment_password} | sudo -S /tmp/disk_filesystem.sh ${local.disk_format_args} > /tmp/disk_filesystem.log",
    ]
  }
}
## This is the main Terraform configuration file for the module vsphere-rocky-9.3-module
## Author Joe Harrison

data "vsphere_datacenter" "dc" {
  name                  = var.vsphere_config.datacenter
}

data "vsphere_datastore" "datastore" {
  name                  = var.vsphere_config.datastore
  datacenter_id         = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name                  = var.vsphere_config.cluster
  datacenter_id         = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vm_network" {
  name                  = var.vsphere_config.vm_network
  datacenter_id         = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name                  = var.rocky-host.template
  datacenter_id         = data.vsphere_datacenter.dc.id
}

# Creating the rocky host
resource "vsphere_virtual_machine" "rocky-host" {

  # Delete VM before recreating 
  lifecycle {
    create_before_destroy = false
  }
  
  count                 = length(split(",", var.rocky-host["mgmt_ips"]))
  name                  = "${var.rocky-host["hostname"]}-${format("%02d", count.index + 1)}"
  resource_pool_id      = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id

  folder                = var.vsphere_config.vm_folder
  
  firmware              = data.vsphere_virtual_machine.template.firmware

  num_cpus              = var.rocky-host.num_cpus
  memory                = var.rocky-host.memory
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  
  scsi_type             = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id          = data.vsphere_network.vm_network.id
    adapter_type        = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label               = "disk0"
    size                = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub       = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned    = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  cdrom {
    client_device       = true
  }
  
  clone {
    template_uuid       = data.vsphere_virtual_machine.template.id
    linked_clone        = "false"

    customize {
      linux_options {
        host_name = "${var.rocky-host["hostname"]}-${format("%02d", count.index + 1)}"
        domain    = "local"
      }

      network_interface {
        ipv4_address = split(",", var.rocky-host["mgmt_ips"])[count.index]
        ipv4_netmask = var.rocky-host.mgmt_subnet
      }

      ipv4_gateway = var.rocky-host.mgmt_gateway
      dns_server_list = split(",", var.rocky-host["mgmt_dns_servers"])
  }
  
}

  # Connection block for remote-exec
  connection {
    type     = "ssh"
    user     = "admin"
    password = var.rocky-host.ssh_password
    host     = self.default_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl enable firewalld",
      "sudo systemctl start firewalld",
      "sudo touch /etc/cloud/cloud-init.disabled"
    ]
  }

}

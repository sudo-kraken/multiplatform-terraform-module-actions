## This is the main Terraform configuration file for the module vsphere-ws19-module
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
  name                  = var.ws19.template
  datacenter_id         = data.vsphere_datacenter.dc.id
}

resource "random_password" "password" {
  length           = 16
  special          = true
  min_numeric      = 2
  min_special      = 2
  override_special = "!@$"
}

data "template_file" "init" {
  template = file("${path.module}/templates/bootstrap.ps1")
  vars = {
    adpass   = var.ws19.ADPass
    adou     = var.ws19.ADOU
    aduser   = var.ws19.ADUser
    addomain = var.ws19.ADDomain
    adjoin   = var.ws19.ADJoin
    gateway  = var.ws19.vm_gateway
  }
}

#Not used but could be another location to store data
data "template_file" "metadata" {
  template = file("${path.module}/templates/metadata.yaml")
  vars = {

  }
}

# Creating the ws19 vm
resource "vsphere_virtual_machine" "vm" {

  # Delete VM before recreating 
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      extra_config
    ]
  }

  name                  = var.ws19.hostname
  resource_pool_id      = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id

  folder                = var.vsphere_config.vm_folder
  
  firmware              = data.vsphere_virtual_machine.template.firmware

  num_cpus              = var.ws19.num_cpus
  memory                = var.ws19.memory
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  
  scsi_type             = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id          = data.vsphere_network.vm_network.id
    adapter_type        = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label               = "os"
    size                = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub       = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned    = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  dynamic "disk" {
    for_each = var.ws19.vm_disks
    content {
      label            = disk.key
      size             = disk.value["size"]
      eagerly_scrub    = false
      thin_provisioned = disk.value["thinprov"]
      unit_number      = disk.value["unit_number"]
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = false

    customize {
      windows_options {
        computer_name    = var.ws19.hostname
        admin_password   = var.ws19.vm_password == "" ? random_password.password.result : var.ws19.vm_password
        workgroup        = "WORKGROUP"
        auto_logon       = true
        auto_logon_count = 2
        time_zone        = var.ws19.vm_timezone
        run_once_command_list = [
          "powershell \"cd \"$env:ProgramFiles\\VMware\\VMware~1\";[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($(.\\rpctool.exe \\\"info-get guestinfo.userdata\\\")))|out-file C:\\bootstrap.ps1\"",
          "cmd.exe /C Powershell.exe -ExecutionPolicy Bypass -File C:\\bootstrap.ps1"
        ]

      }

      network_interface {
        ipv4_address    = var.ws19.vm_ip
        ipv4_netmask    = var.ws19.vm_netmask
        dns_server_list = var.ws19.vm_dns_servers
        dns_domain      = var.ws19.vm_dns_domain
      }

      ipv4_gateway = var.ws19.vm_gateway

    }
  }

  extra_config = {
    "ethernet1.virtualDev"        = "vmxnet3"
    "ethernet1.present"           = "TRUE"
    "guestinfo.metadata"          = base64encode(data.template_file.metadata.rendered)
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(data.template_file.init.rendered)
    "guestinfo.userdata.encoding" = "base64"
  }

}

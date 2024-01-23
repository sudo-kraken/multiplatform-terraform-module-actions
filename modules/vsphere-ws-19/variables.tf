// Author Joe Harrison
// Define variables for vSphere and WS19 deployment configurations

variable "vsphere_config" {
  type = object({
    vcenter_server = string
    user           = string
    datacenter     = string
    cluster        = string
    datastore      = string
    vm_network     = string
    vm_folder      = string
  })
  description = "vSphere environment and connection details"
}

// WS19 config parameters
variable "ws19" {
  type = object({
    hostname        = string
    vm_password     = string
    num_cpus        = string
    memory          = string
    disk_size       = string
    vm_disks        = list(any)
    ADJoin          = bool
    ADPass          = string
    ADOU            = string
    ADUser          = string
    ADDomain        = string
    vm_ip           = string
    vm_netmask      = string
    vm_dns_servers  = list(string)
    vm_dns_domain   = string
    vm_gateway      = string
    vm_timezone     = string
    template        = string
  })
  description = "Details for the WS19 host"
}

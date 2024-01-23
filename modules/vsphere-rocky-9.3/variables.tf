## Author Joe Harrison
## Define variables for vSphere and rocky deployment configurations

variable "vsphere_config" {
    type                        = map(string)
    description                 = "vSphere environment and connection details"
}

# Admin node config parameters
variable "rocky-host" {
    type                        = map(any)
    description                 = "Details for the rocky host"

}

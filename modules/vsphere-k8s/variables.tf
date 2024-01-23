## Define variables for vSphere and k8s deployment configurations
## Author Joe Harrison

# vSphere config parameters
variable "vsphere_config" {
    type                        = map(string)
    description                 = "vSphere environment and connection details"

}

# Global K8S cluster parameters
variable "k8s-global" {
    type                        = map(string)
    description                 = "Global settings for the k8s cluster"
}

# Admin node config parameters
variable "k8s-admin-node" {
    type                        = map(string)
    description                 = "Details for the k8s administrative node"
}

# K8S node config parameters
variable "k8s-nodes" {
    type                        = map(string)
    description                 = "Details for the k8s worker nodes"
}

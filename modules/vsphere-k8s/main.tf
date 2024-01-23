## This is the main Terraform configuration file for the module vsphere-k8s-module
## Author Joe Harrison

# Locals block for storing the command to change Kubernetes version or use default version
locals {
  change_kube_version = "sed -i 's/kube_version: .*/kube_version: ${var.k8s-global.kube_version}/g' ~/kubespray/inventory/k8s-on-vmware/group_vars/k8s-cluster/k8s-cluster.yml"
  default_kube_version = "echo \"Using default Kubespray version for Kubernetes deployment\""
}

# Resource to generate a public/private key for passwordless authentication
resource "null_resource" "generate-sshkey" {

    # Provisioner to generate the ssh key using ssh-keygen command
    provisioner "local-exec" {
        command = "yes n | ssh-keygen -b 4096 -t rsa -C 'k8s-on-vmware-sshkey' -N '' -f ${var.k8s-global.private_key}"
        on_failure = continue
    }
}

# Data source to read the contents of the ssh private key file
data "local_file" "ssh-privatekey" {
  filename            = "${var.k8s-global.private_key}"

  depends_on = [
    null_resource.generate-sshkey,
  ]
}

# Data source to read the contents of the ssh public key file
data "local_file" "ssh-publickey" {
  filename            = "${var.k8s-global.public_key}"

  depends_on = [
    null_resource.generate-sshkey,
  ]
}

# External modules to output the contents of the ssh private key
# It uses an external shell resource provided by Invicton-Labs.
module "private_key_output" {
  source  = "Invicton-Labs/shell-resource/external"
  version = "0.4.1"
  command_unix = "cat ${var.k8s-global.private_key}"
  fail_create_on_stderr = false
  depends_on = [
    null_resource.generate-sshkey,
  ]
}

# External modules to output the contents of the ssh public key
# It uses an external shell resource provided by Invicton-Labs.
module "public_key_output" {
  source  = "Invicton-Labs/shell-resource/external"
  version = "0.4.1"
  command_unix = "cat ${var.k8s-global.public_key}"
  fail_create_on_stderr = false
  depends_on = [
    null_resource.generate-sshkey,
  ]
}

# AWS Encryption Key For S3 Backend
# This resource represents the AWS Key Management Service (KMS) key used to encrypt the S3 backend.
resource "aws_kms_key" "tf_state_key" {
  description             = "This key is used to encrypt ${var.k8s-nodes.hostname}tf-state bucket objects"
  deletion_window_in_days = 10
  
}

# Add Key Alias
resource "aws_kms_alias" "tf_state_key" {
  name          = "alias/${var.k8s-nodes.hostname}tf-state_key"
  target_key_id = aws_kms_key.tf_state_key.key_id
}

# AWS S3 bucket resource that will be used for storing the Terraform state file.
# The bucket name is derived from the k8s-nodes hostname and suffixed with 'tf-state'.
resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.k8s-nodes.hostname}tf-state"
}

# Configuration for server-side encryption (SSE) of the S3 bucket.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf_state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Enable versioning for the S3 bucket.
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules for the S3 bucket.
resource "aws_s3_bucket_lifecycle_configuration" "tf_state_lifecycle" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id      = "retain-noncurrent-versions"
    status  = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days  = 30
    }
  }
}

# DynamoDB resource to be used for state file locking and consistency checking.
# The table name is derived from the k8s-nodes hostname and suffixed with 'tf-lock'.
resource "aws_dynamodb_table" "tf_lock" {
 name          = "${var.k8s-nodes.hostname}tf-lock"
 billing_mode  = "PAY_PER_REQUEST"
 hash_key      = "LockID"

 # Definition of the primary key attribute for the table.
 attribute {
   name  = "LockID"
   type  = "S"   # S indicates that the attribute is of type string.
 }
}

# This data source block retrieves information about a specific vSphere datacenter 
# identified by the name specified in the vsphere_config variable.
data "vsphere_datacenter" "dc" {
  name                  = var.vsphere_config.datacenter
}

# This data source block retrieves information about a specific vSphere datastore 
# within the datacenter identified above.
data "vsphere_datastore" "datastore" {
  name                  = var.vsphere_config.datastore
  datacenter_id         = data.vsphere_datacenter.dc.id
}

# This data source block retrieves information about a specific vSphere compute cluster 
# within the datacenter identified above.
data "vsphere_compute_cluster" "cluster" {
  name                  = var.vsphere_config.cluster
  datacenter_id         = data.vsphere_datacenter.dc.id
}

# This data source block retrieves information about a specific vSphere network 
# within the datacenter identified above.
data "vsphere_network" "vm_network" {
  name                  = var.vsphere_config.vm_network
  datacenter_id         = data.vsphere_datacenter.dc.id
}

# This data source block retrieves information about a specific vSphere virtual machine template
# within the datacenter identified above.
data "vsphere_virtual_machine" "template" {
  name                  = var.k8s-admin-node.template
  datacenter_id         = data.vsphere_datacenter.dc.id
}

# Resource block that creates the administrative node for the Kubernetes cluster on vSphere
resource "vsphere_virtual_machine" "k8s-admin-node" {

  # The lifecycle block instructs Terraform not to create a new instance before destroying the old one.
  # Setting `create_before_destroy` to false is the default behavior.
  lifecycle {
    create_before_destroy = false
    prevent_destroy       = true
  }

  # The name of the virtual machine as it will appear on vSphere
  name                  = var.k8s-admin-node.hostname

  # The ID of the resource pool in which the virtual machine will be created
  resource_pool_id      = data.vsphere_compute_cluster.cluster.resource_pool_id
  
  # The ID of the datastore where the virtual machine will be stored
  datastore_id          = data.vsphere_datastore.datastore.id

  # The vSphere folder where the virtual machine will be placed
  folder                = var.vsphere_config.vm_folder
  
  # The type of firmware the virtual machine will use (e.g. BIOS or UEFI)
  firmware              = data.vsphere_virtual_machine.template.firmware

  # The number of virtual CPUs and the amount of memory the virtual machine
  num_cpus              = var.k8s-admin-node.num_cpus
  memory                = var.k8s-admin-node.memory
  
  # The guest OS ID that the virtual machine will use
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  
  # The type of SCSI controller the virtual machine will use
  scsi_type             = data.vsphere_virtual_machine.template.scsi_type

  # Network interface configuration
  network_interface {
    network_id          = data.vsphere_network.vm_network.id
    adapter_type        = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # Disk configuration
  disk {
    label               = "disk0"
    size                = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub       = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned    = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  # CD-ROM configuration
  cdrom {
    client_device       = true
  }
  
  # vApp properties configuration, including hostname and user data for cloud-init
  vapp {
    properties = {
      hostname          = var.k8s-admin-node.hostname
      user-data         = base64encode(templatefile("${path.module}/templates/adminhost-cloud-init-rocky.yml", { 
        username = var.k8s-global.username, 
        public-key = data.local_file.ssh-publickey.content, 
        mgmt-ip-addr = "${var.k8s-admin-node.mgmt_ip}", 
        mgmt-int-name = var.k8s-admin-node.mgmt_interface_name, 
        mgmt-use-dhcp = var.k8s-admin-node.mgmt_use_dhcp, 
        mgmt-ip-gw = var.k8s-admin-node.mgmt_gateway, 
        mgmt-dns = var.k8s-admin-node.mgmt_dns_servers, 
        timezone = var.k8s-global.timezone
      }))
    }
  }
  
  # Virtual machine clone configuration
  clone {
    template_uuid       = data.vsphere_virtual_machine.template.id
    linked_clone        = "false"
  }

  # The timeout for waiting for the guest network to be available, in seconds
  wait_for_guest_net_timeout = 10
  
  # Dependencies for the virtual machine creation
  depends_on = [
    data.local_file.ssh-publickey,
    data.local_file.ssh-privatekey,
  ]
}

# Resource block that creates the worker nodes for the Kubernetes cluster on vSphere
resource "vsphere_virtual_machine" "k8s-nodes" {

  # The lifecycle block instructs Terraform not to create a new instance before destroying the old one.
  # Setting `create_before_destroy` to false is the default behavior. 
  lifecycle {
    create_before_destroy = false
    prevent_destroy       = true
  }
  
  # The number of instances of this virtual machine to be created
  count                 = var.k8s-nodes.number_of_nodes

  # The name of the virtual machine as it will appear on vSphere
  name                  = count.index < var.k8s-nodes.mgmt_m_nodes_total ? "${var.k8s-nodes.hostname}m${count.index + 1}" : "${var.k8s-nodes.hostname}w${count.index - var.k8s-nodes.mgmt_m_nodes_total + 1}"
  
  # The ID of the resource pool in which the virtual machine will be created
  resource_pool_id      = data.vsphere_compute_cluster.cluster.resource_pool_id

  # The ID of the datastore where the virtual machine will be stored
  datastore_id          = data.vsphere_datastore.datastore.id
  
  # The vSphere folder where the virtual machine will be placed
  folder                = var.vsphere_config.vm_folder
  
  # The type of firmware the virtual machine will use (e.g. BIOS or UEFI)
  firmware = data.vsphere_virtual_machine.template.firmware

  # The number of virtual CPUs and the amount of memory the virtual machine
  num_cpus              = var.k8s-nodes.num_cpus
  memory                = var.k8s-nodes.memory

  # The guest OS ID that the virtual machine will use
  guest_id              = data.vsphere_virtual_machine.template.guest_id

  # The type of SCSI controller the virtual machine will use
  scsi_type             = data.vsphere_virtual_machine.template.scsi_type

  # Network interface configuration
  network_interface {
    network_id          = data.vsphere_network.vm_network.id
    adapter_type        = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  
  # Disk configuration
  disk {
    label               = "disk0"
    size                = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub       = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned    = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  
  # CD-ROM configuration
  cdrom {
    client_device       = true
  }

  # vApp properties configuration, including hostname and user data for cloud-init
  vapp {
    properties = {
      hostname          = count.index < var.k8s-nodes.mgmt_m_nodes_total ? "${var.k8s-nodes.hostname}m${count.index + 1}" : "${var.k8s-nodes.hostname}w${count.index - var.k8s-nodes.mgmt_m_nodes_total + 1}"
      user-data = base64encode(templatefile("${path.module}/templates/k8snodes-cloud-init-rocky.yml", { 
        username = var.k8s-global.username, 
        public-key = data.local_file.ssh-publickey.content, 
        mgmt-ip-addr = format("%s.%s.%s.%d", split(".", var.k8s-nodes.mgmt_startip)[0], split(".", var.k8s-nodes.mgmt_startip)[1], split(".", var.k8s-nodes.mgmt_startip)[2], split(".", var.k8s-nodes.mgmt_startip)[3] + count.index),
        mgmt-ip-subnet = var.k8s-nodes.mgmt_subnet,
        mgmt-int-name = var.k8s-nodes.mgmt_interface_name, 
        mgmt-use-dhcp = var.k8s-nodes.mgmt_use_dhcp, 
        mgmt-ip-gw = var.k8s-nodes.mgmt_gateway, 
        mgmt-dns = var.k8s-nodes.mgmt_dns_servers, 
        timezone = var.k8s-global.timezone 
      }))
    }
  }
  
  # Virtual machine clone configuration
  clone {
    template_uuid       = data.vsphere_virtual_machine.template.id
    linked_clone        = "false"
  }

  # The timeout for waiting for the guest network to be available, in seconds
  wait_for_guest_net_timeout = 10

  # Dependencies for the virtual machine creation
  depends_on = [
    data.local_file.ssh-publickey,
  ]
}

locals {
  # If DHCP is not used, use the statically assigned IP address for the admin node; otherwise, use the default IP address assigned by DHCP
  admin_node_ip = var.k8s-admin-node.mgmt_use_dhcp != "no" ? vsphere_virtual_machine.k8s-admin-node.default_ip_address : split("/", var.k8s-admin-node.mgmt_ip)[0]
  # The total number of master nodes
  master_nodes = var.k8s-nodes.mgmt_m_nodes_total
  # The list of IPs for the nodes
  node_ips = split(",", var.k8s-nodes.mgmt_node_ips)
}

# The cloud-init-admin-node resource is used to run remote commands on the created vSphere virtual machine
# It waits until the /etc/cloud/cloud-init.done file exists on the virtual machine
resource "null_resource" "cloud-init-admin-node" {
  # The triggers argument allows to recreate the resource whenever the build_number value changes
  triggers = {
    build_number = 2
  }
  
  # Define the SSH connection to the VM
  connection {
    host         = vsphere_virtual_machine.k8s-admin-node.default_ip_address
    type         = "ssh"
    user         = var.k8s-global.username
    private_key  = file(var.k8s-global.private_key)
  }

  # This provisioner is used to execute commands on the virtual machine
  # It will check every 2 seconds if the cloud-init.done file exists
  provisioner "remote-exec" {
    inline      = ["while [ ! -f /etc/cloud/cloud-init.done ]; do sleep 2; done"]
    on_failure  = continue
  }
}

# This resource block is used to copy the public and private SSH keys to the master node for passwordless authentication
resource "null_resource" "set-public-key" {
  # The resource will be recreated each time the build_number value changes
  triggers = {
     build_number = 2
  }
  
  # Define the SSH connection to the VM
  connection {
    host = local.admin_node_ip
    type = "ssh"
    user = var.k8s-global.username
    private_key = file(var.k8s-global.private_key)
  }

  # This provisioner is used to copy the private key to the virtual machine
  provisioner "file" {
    source          = var.k8s-global.private_key
    destination     = "/home/k8sadmin/.ssh/id_rsa"
  }

  # This provisioner is used to copy the public key to the virtual machine
  provisioner "file" {
    source          = var.k8s-global.public_key
    destination     = "/home/k8sadmin/.ssh/id_rsa.pub"
  }

  # This provisioner is used to change the permissions of the private key
  provisioner "remote-exec" {
    inline         = ["chmod 600 /home/k8sadmin/.ssh/id_rsa",]
  }

  # This resource depends on the completion of the cloud-init-admin-node resource
  depends_on = [
    null_resource.cloud-init-admin-node,
  ]
}

# This resource block appears to be the beginning of a block that will handle preparing Kubespray on the VM
# Currently, it only sets up the SSH connection information and doesn't specify any actions to be taken
resource "null_resource" "prepare-kubespray" {
  connection {
    host = local.admin_node_ip
    type = "ssh"
    user = var.k8s-global.username
    private_key = file(var.k8s-global.private_key)
  }
  
  # This provisioner executes a series of commands remotely on the created VMs.
  provisioner "remote-exec" {
    inline = [
      # Download the latest stable version of kubectl
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      # Make kubectl executable
      "chmod +x kubectl",
      # Move kubectl into PATH
      "sudo mv kubectl /usr/local/bin/",
      # Update the system
      "sudo dnf update -y",
      # Install python3-pip and git
      "sudo dnf install python3-pip git -y",
      # Upgrade pip
      "pip3 install --upgrade pip",
      # Clone the Kubespray repository
      "git clone https://github.com/kubernetes-sigs/kubespray.git",
      # Go to kubespray directory
      "cd ~/kubespray",
      # Install requirements from Kubespray
      "pip3 install -U -r requirements.txt",
      # Copy sample inventory for your own cluster
      "cp -rfp inventory/sample inventory/k8s-on-vmware",
      # Choose Kubernetes version (based on variable value)
      "${var.k8s-global.kube_version != "default" ? local.change_kube_version : local.default_kube_version}",
      # Generate a script for running Kubespray
      "echo \"#!/bin/bash\" > ~/run-kubespray.sh",
      "echo \"cd ~/kubespray/\" >> ~/run-kubespray.sh",
      "echo \"~/.local/bin/ansible-playbook -i inventory/k8s-on-vmware/hosts.yml --become --become-user=root cluster.yml\" >> ~/run-kubespray.sh",
      # Go back to home directory and setup Kubernetes configuration
      "echo \"cd ~/\" >> ~/run-kubespray.sh",
      "echo \"mkdir -p .kube\" >> ~/run-kubespray.sh",
      "echo \"ssh -oStrictHostKeyChecking=no -oIdentitiesOnly=yes ${local.node_ips[0]} sudo cp /etc/kubernetes/admin.conf ~/config\" >> ~/run-kubespray.sh",
      "echo \"ssh -oStrictHostKeyChecking=no -oIdentitiesOnly=yes ${local.node_ips[0]} sudo chown ${var.k8s-global.username}:${var.k8s-global.username} ~/config\" >> ~/run-kubespray.sh",
      # Make ~/.kube path
      "echo \"sudo mkdir -p ~/.kube\" >> ~/run-kubespray.sh",
      # Copy Kubernetes configuration to local .kube directory
      "echo \"scp -oStrictHostKeyChecking=no -oIdentitiesOnly=yes ${local.node_ips[0]}:~/config ~/.kube/config\" >> ~/run-kubespray.sh",
      # Replace localhost with the actual IP
      "echo \"sudo sed -i \"s/127.0.0.1/${local.node_ips[0]}/g\" ~/.kube/config\" >> ~/run-kubespray.sh",
      # Remove the copied config file
      "echo \"ssh -oStrictHostKeyChecking=no -oIdentitiesOnly=yes ${local.node_ips[0]} rm ~/config\" >> ~/run-kubespray.sh",
      # Make the Kubespray script executable
      "chmod +x ~/run-kubespray.sh"
    ]
  }
  
  # Ensure this resource executes after the other specified resources have been created
  depends_on = [
    vsphere_virtual_machine.k8s-admin-node,
    vsphere_virtual_machine.k8s-nodes,
    null_resource.set-public-key,
    null_resource.cloud-init-admin-node,
  ]
}

# Define a new null_resource for generating a hosts.yaml file
resource "null_resource" "generate_hosts_yaml" {
  connection {
    # Connect to the admin node
    host        = local.admin_node_ip
    type        = "ssh"
    user        = var.k8s-global.username
    private_key = file(var.k8s-global.private_key)
  }
  
  # Provisioner that creates a YAML file for the Kubernetes cluster configuration
  provisioner "remote-exec" {
    inline = [<<EOT
      # Create a new hosts.yml file in the Kubespray inventory directory
      echo 'all:' > ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '  hosts:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      
      # Generate entries for master nodes
      %{ for i, ip in local.node_ips ~}
        %{ if i < local.master_nodes ~}
          # For each master node, add a new entry with hostname, ansible_host, ip, and access_ip
          echo '    ${var.k8s-nodes.hostname}m${(i + 1)}:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      ansible_host: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      ip: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      access_ip: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
        %{ endif ~}
      %{ endfor ~}

      # Generate entries for worker nodes
      %{ for i, ip in local.node_ips ~}
        %{ if i >= local.master_nodes ~}
          # For each worker node, add a new entry with hostname, ansible_host, ip, and access_ip
          echo '    ${var.k8s-nodes.hostname}w${(i + 1 - local.master_nodes)}:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      ansible_host: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      ip: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
          echo '      access_ip: ${ip}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
        %{ endif ~}
      %{ endfor ~}
      
      # Add remaining lines to the hosts.yml file
      echo '  children:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '    kube_control_plane:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '      hosts:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      
      # Add master nodes to kube_control_plane
      %{ for i, ip in local.node_ips ~}
        %{ if i < local.master_nodes ~}
          echo '        ${var.k8s-nodes.hostname}m${(i + 1)}:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
        %{ endif ~}
      %{ endfor ~}
      echo '    kube_node:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '      hosts:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      
      # Add worker nodes to kube_node
      %{ for i, ip in local.node_ips ~}
        %{ if i >= local.master_nodes ~}
          echo '        ${var.k8s-nodes.hostname}w${(i + 1 - local.master_nodes)}:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
        %{ endif ~}
      %{ endfor ~}
      echo '    etcd:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '      hosts:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      
      # Add master nodes to etcd
      %{ for i, ip in local.node_ips ~}
        %{ if i < local.master_nodes ~}
          echo '        ${var.k8s-nodes.hostname}m${(i + 1)}:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
        %{ endif ~}
      %{ endfor ~}
      
      # Add remaining lines to the hosts.yml file
      echo '    k8s_cluster:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '      children:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '        kube_control_plane:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '        kube_node:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '    calico_rr:' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
      echo '      hosts: {}' >> ~/kubespray/inventory/k8s-on-vmware/hosts.yml
    EOT
    ]
  }
  
  # This resource should only be created after `null_resource.prepare-kubespray`
  depends_on = [
    null_resource.prepare-kubespray,
  ]
}

# This resource runs the Kubespray script remotely
resource "null_resource" "run-kubespray" {
  # Only create this resource if the `run_kubespray` variable is set to "yes"
  count = var.k8s-global.run_kubespray == "yes" ? 1 : 0
  
  connection {
    host = local.admin_node_ip
    type = "ssh"
    user = var.k8s-global.username
    private_key = file(var.k8s-global.private_key)
  }
 
  # Run the Kubespray script
  provisioner "remote-exec" {
    inline = [
      "cd ~/",
      "~/run-kubespray.sh",
    ]
  }
  
  # This resource should only be created after `null_resource.generate_hosts_yaml`
  depends_on = [
    null_resource.generate_hosts_yaml,
  ]
}

# Output the contents of the generated private key
output "private-key" {
  value = module.private_key_output.stdout
}

# Output the contents of the generated public key  
output "public-key" {
  value = module.public_key_output.stdout
}

# Output the IP address of the admin node
output "k8s-admin-node-ip" {
  value = local.admin_node_ip
}

# Output the IP addresses of all nodes
output "k8s-node-ips" {
  value = local.node_ips
}

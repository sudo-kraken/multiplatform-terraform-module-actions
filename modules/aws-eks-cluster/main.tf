# Fetch the current AWS account details
data "aws_caller_identity" "current" {}

# Fetch the vpc private subnet details
data "aws_subnet" "private" {
  count = length(var.subnet_ids)

  id = var.subnet_ids[count.index]
}

# Create a KMS key for EKS cluster secrets
resource "aws_kms_key" "eks" {
  description = "KMS key for EKS ${var.name}"
  # The number of days to retain the key before deletion, left commented for reference
  #deletion_window_in_days = 10

  # Tags for the KMS key
  tags = {
    Name          = "${var.name}-key"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Create an alias for the KMS key
resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}-key"
  target_key_id = aws_kms_key.eks.key_id
}

# Define the IAM role for the EKS cluster with necessary permissions
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.name}-cluster-role"
  
  # Define the trust relationship policy for the role to allow EKS to assume it
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })

  # Tags for the EKS cluster IAM role
  tags = {
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag

  }
}

# Attach required AWS managed policies to the EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_role_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# Define a security group for the EKS cluster to control inbound and outbound traffic
resource "aws_security_group" "eks_cluster_sg" {
  name   = "${var.name}-sg-01"
  vpc_id = var.vpc_id

  # Egress rule to allow outbound traffic from the EKS cluster to the Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule to allow all inbound traffic to the EKS cluster, adjust as needed
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags for the EKS cluster security group
  tags = {
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Define the EKS cluster configuration including version, network settings, and logging
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version
  
  enabled_cluster_log_types = ["scheduler", "api", "controllerManager", "authenticator", "audit"]

  # Encryption configuration for EKS secrets
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  # Kubernetes network configuration for the EKS cluster
  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  # VPC configuration for the EKS cluster, including security groups and subnets
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    subnet_ids              = var.subnet_ids
  }
  
  # Tags for the EKS cluster
  tags = {
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# AWS EKS Add-ons: These are the additional integrations you can enable with your EKS clusters
resource "aws_eks_addon" "addons" {
  for_each                    = { for addon in var.addons : addon.name => addon }
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = each.value.name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Make sure addons are deployed after the EKS cluster is created
  depends_on = [aws_eks_node_group.eks_ng]
}

# IAM Role for EKS Worker Nodes: This defines the permissions that your worker nodes will have. 
# This is separate from the EKS Cluster role because the worker nodes might need permissions that your cluster itself does not need
resource "aws_iam_role" "eks_cluster_worker_role" {
  name = "${var.name}-worker-role"
  
  # Policy that allows EC2 instances to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
  
  # Tags for the EKS worker nodes IAM role
  tags = {
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag

  }
}

# Attaching standard AWS policies to the EKS Worker Nodes IAM role. These policies grant permissions 
# required for the nodes to communicate with other AWS services
resource "aws_iam_role_policy_attachment" "eks_cluster_attach_policy_to_worker_role" {
  for_each = {
    "AmazonEKSWorkerNodePolicy"          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "AmazonEKS_CNI_Policy"               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "AmazonEBSCSIDriverPolicy"           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    "AmazonEFSCSIDriverPolicy"           = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  }

  role       = aws_iam_role.eks_cluster_worker_role.name
  policy_arn = each.value
}

# A local definition to generate user-data script for bootstrapping EKS worker nodes
locals {
  eks-node-private-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii" 

#!/bin/bash -xe
sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority[0].data}' --dns-cluster-ip '${var.core_dns_ip}' '${aws_eks_cluster.eks_cluster.name}'
echo "Running custom user data script" > /tmp/me.txt
yum install -y amazon-ssm-agent
echo "yum'd agent" >> /tmp/me.txt
systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
date >> /tmp/me.txt
--==MYBOUNDARY==--
USERDATA
}

# Launch Template for Worker Nodes: Launch templates are used to create EC2 instance configurations that can be reused to launch instances
data "aws_ssm_parameter" "eks_ami" {
  name=format("/aws/service/eks/optimized-ami/%s/amazon-linux-2/recommended/image_id", aws_eks_cluster.eks_cluster.version)
}

resource "aws_launch_template" "eks_workers" {
  name_prefix   = "${var.name}-worker"
  image_id      = data.aws_ssm_parameter.eks_ami.value

  vpc_security_group_ids = [aws_security_group.eks_worker_nodes_sg.id]
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 100
      volume_type = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name                                = "${var.name}-worker"
      "kubernetes.io/cluster/${var.name}" = "owned"
      managed-by                          = "terraform"
      client                              = var.client_tag
      environment                         = var.environment_tag
    }
  }

  user_data = base64encode(local.eks-node-private-userdata)
  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

# Security Group for Worker Nodes: This defines the network permissions for the instances that will act as worker nodes in the EKS cluster
resource "aws_security_group" "eks_worker_nodes_sg" {
  name   = "${var.name}-worker-nodes-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name          = "${var.name}-worker-nodes-sg"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

resource "aws_security_group_rule" "eks_worker_nodes_sg_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" 
  security_group_id = aws_security_group.eks_worker_nodes_sg.id
  self              = true
}

resource "aws_security_group_rule" "eks_workers_ingress_private_subnets" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_worker_nodes_sg.id
  cidr_blocks       = [for subnet in data.aws_subnet.private : subnet.cidr_block]
}

# A resource to generate a random number, used for creating unique resource names.
resource random_id name_entropy {
  byte_length = 4
}

# Create the EKS worker nodes
locals {
  node_pools_map = { for pool in var.node_pools : pool.node_group_name => pool }
}

# Create EKS Worker Node Groups: These are groups of worker nodes with shared configurations
# You might have different node groups for different types of workloads
resource "aws_eks_node_group" "eks_ng" {
  for_each        = local.node_pools_map
  capacity_type   = each.value.capacity_type 
  cluster_name    = aws_eks_cluster.eks_cluster.name   
  labels          = each.value.labels
  node_group_name = "${each.value.node_group_name}-${random_id.name_entropy.hex}"
  node_role_arn   = aws_iam_role.eks_cluster_worker_role.arn
  subnet_ids      = each.value.subnet_ids
  tags            = each.value.tags

  instance_types  = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  launch_template {
    name    = aws_launch_template.eks_workers.name
    version = aws_launch_template.eks_workers.latest_version
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach_policy_to_worker_role,
    aws_launch_template.eks_workers
  ]

  lifecycle {
    create_before_destroy = false
  }
}

# Generate a new SSH key pair
resource "tls_private_key" "jumpbox_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Import the generated public key into AWS
resource "aws_key_pair" "jumpbox_aws_key" {
  key_name   = "${var.name}-jumpbox-key"
  public_key = tls_private_key.jumpbox_key.public_key_openssh
}

# Write the private key to a file
resource "local_file" "private_key" {
  content  = tls_private_key.jumpbox_key.private_key_pem
  filename = "${path.module}/private_key.pem"

  lifecycle {
    ignore_changes = [content, filename]
  }
}

# Security Group for the EC2 jump box
resource "aws_security_group" "jumpbox_sg" {
  name        = "${var.name}-jumpbox-sg"
  description = "Security Group for RDP access to the jump box"
  vpc_id      = var.vpc_id

  # Ingress rule to allow RDP access only from the current runner's IP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name          = "${var.name}-jumpbox-sg"
    managed-by    = "terraform"
    client        = var.client_tag
    product       = var.product_tag
    environment   = var.environment_tag
  }
}

# EC2 Instance acting as a Jump Box
resource "aws_instance" "jumpbox" {
  ami           = "ami-004128c5853c91821"  # Windows AMI
  instance_type = "t3a.large"
  key_name      = aws_key_pair.jumpbox_aws_key.key_name
  subnet_id     = var.public_subnet_id  

  vpc_security_group_ids = [
    aws_security_group.jumpbox_sg.id
  ]

  user_data = <<-EOF
              <powershell>
              # Enable WinRM
              Enable-PSRemoting -Force

              # Install Chocolatey
              Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

              # Install Chocolatey packages
              choco install kubernetes-cli awscli git lens kubernetes-helm -y

              # Configure AWS CLI (Replace with your actual AWS credentials and settings)
              cd "C:\Program Files\Amazon\AWSCLIV2\"
              & .\aws.exe configure set aws_access_key_id ${var.aws_access}
              & .\aws.exe configure set aws_secret_access_key ${var.aws_secret}
              & .\aws.exe configure set default.region eu-west-2
              & .\aws.exe configure set default.output json
              & .\aws.exe eks update-kubeconfig --name ${var.name}
              </powershell>
              EOF

  tags = {
    Name          = "${var.name}-jumpbox"
    managed-by    = "terraform"
    client        = var.client_tag
    product       = var.product_tag
    environment   = var.environment_tag
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.eks_ng,
    aws_eks_addon.addons
  ]

}
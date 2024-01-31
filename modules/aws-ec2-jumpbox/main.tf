# Fetch the current AWS account details
data "aws_caller_identity" "current" {}

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

# Save key to file on the runner 
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

  # Ingress rule to allow RDP access
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
              aws configure set aws_access_key_id ${var.aws_access}
              aws configure set aws_secret_access_key ${var.aws_secret}
              aws configure set default.region eu-west-2
              aws configure set default.output json
              aws eks update-kubeconfig --name ${var.name}
              </powershell>
              EOF

  tags = {
    Name          = "${var.name}-jumpbox"
    managed-by    = "terraform"
    client        = var.client_tag
    product       = var.product_tag
    environment   = var.environment_tag
  }
}

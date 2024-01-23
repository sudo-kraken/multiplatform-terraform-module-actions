provider "aws" {
  region = var.region
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name          = var.vpc_name
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name          = "${var.vpc_name}-igw"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain        = "vpc"
  depends_on    = [aws_internet_gateway.igw]
  
  tags = {
    Name          = "${var.vpc_name}-nat-eip"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Create the NAT Gateway and attach it to the VPC
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name          = "${var.vpc_name}-ngw"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Create public subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  map_public_ip_on_launch = true

  tags = merge({
    Name          = "${var.vpc_name}-public-subnet-${count.index + 1}"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  },
  var.is_eks_enabled ? {
    "kubernetes.io/role/elb" = "1"
  } : {}
  )
}

# Create private subnets
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge({
    Name          = "${var.vpc_name}-private-subnet-${count.index + 1}"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  },
  var.is_eks_enabled ? {
    "kubernetes.io/role/internal-elb" = "1"
  } : {}
  )
}

# Create public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name          = "${var.vpc_name}-public-route-table"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Create private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name          = "${var.vpc_name}-private-route-table"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public_subnet_associations" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate private route table with private subnets
resource "aws_route_table_association" "private_subnet_associations" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Manage the default NACL created with the VPC
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  # Inbound Rules
  ingress {
    protocol   = 6  # TCP
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535  # Ephemeral Ports
  }

  ingress {
    protocol   = 6  # TCP
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443  # Kubernetes API Server
  }

  ingress {
    protocol   = 6  # TCP
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22  # SSH
  }

  ingress {
    protocol   = 6
    rule_no    = 104
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  # Outbound Rules
  egress {
    protocol   = -1  # All protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0  # All ports
  }

  tags = {
    Name          = "${var.vpc_name}-default-nacl"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name          = "${var.vpc_name}-default-route-table"
    managed-by    = "terraform"
    client        = var.client_tag
    environment   = var.environment_tag
  }
}




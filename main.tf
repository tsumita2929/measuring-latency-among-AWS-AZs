#############################################################################
# VPC
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
#############################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.region_name}VPC"
  cidr = "10.0.0.0/16"

  azs             = var.availability_zone_names
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

#############################################################################
# SSH Key-Pair
#############################################################################
# Key file name
locals {
  key_pair_name    = "AWS-${var.region_name}-Check-latency"
  public_key_file  = "./${local.key_pair_name}.pub"
  private_key_file = "./${local.key_pair_name}.pem"
}

# Create private key file
resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem

  # Modify permission
  provisioner "local-exec" {
    command = "chmod 400 ${local.private_key_file}"
  }
}

# Create public key file
resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh

  # Modify permission
  provisioner "local-exec" {
    command = "chmod 400 ${local.public_key_file}"
  }
}

# Create private key
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "key_pair" {
  key_name   = local.key_pair_name
  public_key = tls_private_key.keygen.public_key_openssh
}

#############################################################################
# EC2
# https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest
#############################################################################
# EC2 Instances(Public, Run netperf client)
module "ec2_instance_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(module.vpc.azs)

  name = "instance-public-${each.key}"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_pair_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.EC2SecurityGroup.id
  ]
  subnet_id = module.vpc.public_subnets[index(module.vpc.azs, each.value)]

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
  user_data = <<USERDATA
#!/bin/bash
  sudo yum update -y && sudo yum install -y gcc autoconf automake texinfo
  sudo su -
  NETPERF_VER="2.7.0"
  wget -O netperf-$${NETPERF_VER}.tar.gz -c https://github.com/HewlettPackard/netperf/archive/refs/tags/netperf-$${NETPERF_VER}.tar.gz
  tar xf netperf-$${NETPERF_VER}.tar.gz && cd netperf-netperf-$${NETPERF_VER} && ./configure --enable-spin && make -j && make -j install
USERDATA
}

# EC2 Instances(Private, Run netperf server)
module "ec2_instance_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(module.vpc.azs)

  name = "instance-private-${each.key}"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_pair_name
  associate_public_ip_address = false
  vpc_security_group_ids = [
    aws_security_group.EC2SecurityGroup.id
  ]
  subnet_id = module.vpc.private_subnets[index(module.vpc.azs, each.value)]

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
  user_data  = <<USERDATA
#!/bin/bash
  sudo yum update -y && sudo yum install -y gcc autoconf automake texinfo
  sudo su -
  NETPERF_VER="2.7.0"
  wget -O netperf-$${NETPERF_VER}.tar.gz -c https://github.com/HewlettPackard/netperf/archive/refs/tags/netperf-$${NETPERF_VER}.tar.gz
  tar xf netperf-$${NETPERF_VER}.tar.gz && cd netperf-netperf-$${NETPERF_VER} && ./configure --enable-spin && make -j && make -j install
  netserver -4
USERDATA
  # Wait for NAT-GW to be created
  depends_on = [module.vpc]
}

#############################################################################
# Security Group
#############################################################################
resource "aws_security_group" "EC2SecurityGroup" {
  description = "Allows All Traffic from shared security group, and HTTPS outbound traffic"
  name        = "SharedSecurityGroup"
  tags = {
    Name        = "SharedSecurityGroup"
    Terraform   = "true"
    Environment = var.env
  }
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Allow SSH from allow_ssh_ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      var.allow_ssh_ip
    ]
  }
  ingress {
    description = "Allow alll traffic to which SharedSecurityGroup is attached"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  egress {
    description = "Allow alll traffic to which SharedSecurityGroup is attached"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  egress {
    description = "Allow All HTTPS traffic to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

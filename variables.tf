#############################################################################
# Variables
#############################################################################
variable "region" {
  type = string
  # Tokyo
  default = "ap-northeast-1"
  # Osaka
  # default = "ap-northeast-3"
}

variable "availability_zone_names" {
  type = list(string)
  # Tokyo
  default = ["apne1-az1", "apne1-az2", "apne1-az4"]
  # Osaka
  # default = ["apne3-az1", "apne3-az2", "apne3-az3"]
}

variable "region_name" {
  type = string
  # Tokyo
  default = "Tokyo"
  # Osaka
  # default = "Osaka"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "allow_ssh_ip" {
  description = "Source IP address of SSH (ex: 192.0.2.100/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_id" {
  type = string
  # Tokyo
  default = "ami-0218d08a1f9dac831" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type - ami-0218d08a1f9dac831 (64-bit x86)
  # Osaka
  # default     = "ami-0f1ffb565070e6947" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type - ami-0f1ffb565070e6947
}

variable "instance_type" {
  type    = string
  default = "m5.large"
}

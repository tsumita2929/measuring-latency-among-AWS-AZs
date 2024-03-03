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

variable "instance_type" {
  description = "Instance type of EC2 to run the test"
  type        = string
  default     = "m6i.large"
}

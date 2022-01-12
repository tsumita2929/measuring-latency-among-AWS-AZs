#############################################################################
# Outputs
#############################################################################
# Private subnet private IPs
output "instance_private_subnet_private_ips" {
  value = { for x, y in module.ec2_instance_private : x => y.*.private_ip }
}

# Public subnet public IPs
output "instance_public_subnet_public_ips" {
  value = { for x, y in module.ec2_instance_public : x => y.*.public_ip }
}

# Public subnet private IPs
output "instance_public_subnet_private_ips" {
  value = { for x, y in module.ec2_instance_public : x => y.*.private_ip }
}
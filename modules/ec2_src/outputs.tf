output "ec2_network_interfaces" {
  value = aws_instance.ec2_instance.*.primary_network_interface_id
}
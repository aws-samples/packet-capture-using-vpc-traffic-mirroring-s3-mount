output "gwlb_endpoint_service_name" {
  value = aws_vpc_endpoint_service.this.service_name
}

output "gwlb_endpoint_service_type" {
  value = aws_vpc_endpoint_service.this.service_type
}
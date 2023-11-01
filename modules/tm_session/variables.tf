variable "spoke_vpc_id" {
  description = "the spoke VPC where the GWLB Endpoint has to be deployed"
  type        = string
}

variable "spoke_subnet_id" {
  description = "the spoke Subnet where the GWLB Endpoint has to be deployed"
  type        = string
}

variable "gwlb_endpoint_service_name" {
  description = "the gwlb endpoint service name from Hub account"
  type        = string
}

variable "gwlb_endpoint_service_type" {
  description = "the gwlb endpoint service type from Hub account"
  type        = string
}

variable "destination_cidr_block" {
  description = "the destination_cidr_block for traffic mirror filter rule"
  type        = string
}

variable "source_cidr_block" {
  description = "the source_cidr_block for traffic mirror filter rule"
  type        = string
}

variable "src_ec2_count" {
  description = "The number of Amazon EC2 instances for which Traffic Mirroring sessions will have to be established"
  type        = number
}

variable "network_interface_ids" {
  description = "List of IDs of the EC2 instances' ENIs"
  type        = list(string)
}

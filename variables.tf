variable "region" {
  type        = string
  description = "Region where the infrastructure should be deployed."
}

variable "s3_bucket_name" {
  description = "Unique S3 bucket name for storing pcap files"
  type        = string
}

variable "vpc_data_map" {
  type        = map(any)
  description = "A map of VPC information for the hub and spoke VPCs. Contains name, CIDR, and subnet information."
}

variable "sns_notify_email" {
  description = "Email to send SNS notification for Packet Capture systemd services status"
  type        = string
}

variable "hub_account_id" {
  type        = string
  description = "Account ID of the Hub account"
}

variable "spoke_account_1_id" {
  type        = string
  description = "Account ID of the first spoke account"
}

variable "spoke_account_2_id" {
  type        = string
  description = "Account ID of the second spoke account"
}

variable "terraform_deployment_role" {
  type        = string
  description = "IAM role used by Terraform to deploy resources"
}

variable "destination_cidr_block" {
  description = "the destination_cidr_block for traffic mirror filter rule"
  type        = string
}

variable "source_cidr_block" {
  description = "the source_cidr_block for traffic mirror filter rule"
  type        = string
}

variable "allowed_principals" {
  description = "List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. For example `[\"arn:aws:iam::123456789000:root\"]`."
  default     = []
  type        = list(string)
}

variable "default_tags" {
  type = map(string)
  default = {
    project = "packet-captures-s3"
  }
}

variable "load_balancer_type" {
  description = "Load Balancer type to be deployed"
  type        = string
  default     = "gateway"
}

variable "name" {
  description = "Name of the GWLB."
  type        = string
  default     = "traffic-mirroring-gwlb"
}

variable "cross_zone_load_balancing_enabled" {
  description = "if xross zone lb is enabled"
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "if delete protection is enabled"
  type        = bool
  default     = true
}

variable "src_ec2_count" {
  description = "The number of source Amazon EC2 instances for which Traffic Mirroring sessions will have to be established"
  type        = number
  default     = 0
}

variable "traffic_mirror_asg_max_size" {
  description = "Maximum size of the Auto Scaling Group that deploys TCP Dump Agents"
  type        = number
  default     = 0
}

variable "traffic_mirror_asg_min_size" {
  description = "Minimum size of the Auto Scaling Group that deploys TCP Dump Agents"
  type        = number
  default     = 0
}

variable "traffic_mirror_asg_desired_cap" {
  description = "The number of Amazon EC2 instances that should be running in the group that deploys TCP Dump Agents"
  type        = number
  default     = 0
}

variable "traffic_mirror_agent_instance_type" {
  description = "Instance type for TCP Dump agents"
  type        = string
  default     = "m5.xlarge"
}

variable "enable_manual_acceptance" {
  description = "Whether to enable manual acceptance for created VPC endpoint services"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IP address with the launch template's network interfaces."
  default     = true
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = false
  description = "Whether to give public IPs to instances in the VPC when the instances launch"
}
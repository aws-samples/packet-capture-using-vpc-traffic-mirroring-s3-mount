variable "name" {
  description = "Name of the load balancer."
  type        = string
  default     = ""
}

variable "load_balancer_type" {
  description = "Load Balancer type to be deployed"
  type        = string
  default     = "gateway"
}

variable "subnet_ids" {
  description = "pass a list of subnet_ids"
  type        = list(string)
  default     = []
}

variable "subnet_mapping" {
  description = "map of subnet mapping"
  type = map(object({
    subnet_id = string
  }))
  default = {}
}

variable "vpc_id" {
  description = "the vpc where the endpoint needs to be placed"
  type        = string
}

variable "vpc_cidr" {
  description = "the vpc cidr where the endpoint needs to be placed"
  type        = string
}

variable "cross_zone_load_balancing_enabled" {
  description = "if cross zone lb is enabled"
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "if delete protection is enabled"
  type        = bool
  default     = false
}

variable "is_lb_internal" {
  description = "Is the Load balancer internal"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Unique S3 bucket name for storing pcap files"
  type        = string
}

variable "traffic_mirror_asg_max_size" {
  description = "Maximum size of the Auto Scaling Group that deploys TCP Dump Agents"
  type        = number
}

variable "traffic_mirror_asg_min_size" {
  description = "Minimum size of the Auto Scaling Group that deploys TCP Dump Agents"
  type        = number
}

variable "traffic_mirror_asg_desired_cap" {
  description = "The number of Amazon EC2 instances that should be running in the group that deploys TCP Dump Agents"
  type        = number
}

variable "traffic_mirror_agent_instance_type" {
  description = "Instance type for TCP Dump agents"
  type        = string
}

variable "allowed_principals" {
  description = "List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. For example `[\"arn:aws:iam::123456789000:root\"]`."
  default     = []
  type        = list(string)
}

variable "sns_notify_email" {
  description = "Email to send SNS notification for Packet Capture systemd services status"
  type        = string
}

variable "enable_manual_acceptance" {
  description = "Whether to enable manual acceptance for created VPC endpoint services"
  type        = bool
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IP address with the launch template's network interfaces."
}
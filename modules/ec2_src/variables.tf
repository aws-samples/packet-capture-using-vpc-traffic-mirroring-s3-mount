variable "instance_type" {
  type    = string
  default = "m5.xlarge"
}

variable "vpc_id" {
  description = "the vpc where EC2 has to be deployed"
  type        = string
}

variable "subnet_id" {
  description = "the subnet where EC2 has to be deployed"
  type        = string
}

variable "src_ec2_count" {
  description = "The number of Amazon EC2 instances for which Traffic Mirroring sessions will have to be established"
  type        = number
}

variable "src_ec2_ssh_cidr" {
  description = "CIDR to allow SSH into source EC2 instances"
  type        = list(string)
}

variable "vpc_identifier" {
  description = "An identifier for the VPC, used to differentiate between IAM roles"
  type        = string
}
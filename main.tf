locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Set up VPCs for hub and spokes -- would be nice if we could use a for_each, but TF doesn't support that across providers
module "hub_vpc" {
  # checkov:skip=CKV_TF_1:commit hashes cannot be used on Terraform registry sources 
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name                    = "hub"
  cidr                    = var.vpc_data_map.hub.cidr
  private_subnets         = var.vpc_data_map.hub.private_subnets
  public_subnets          = var.vpc_data_map.hub.public_subnets
  azs                     = local.azs
  map_public_ip_on_launch = var.map_public_ip_on_launch

  providers = {
    aws = aws.hub
  }
}

#Adding Interface endpoint for KMS service
resource "aws_vpc_endpoint" "kms_endpoint_hub" {
  vpc_id            = module.hub_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"
}

module "spoke_vpc1" {
  # checkov:skip=CKV_TF_1:commit hashes cannot be used on Terraform registry sources 
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name            = "spoke_1"
  cidr            = var.vpc_data_map.spoke_1.cidr
  private_subnets = var.vpc_data_map.spoke_1.private_subnets
  public_subnets  = var.vpc_data_map.spoke_1.public_subnets
  azs             = local.azs

  providers = {
    aws = aws.spoke_1
  }
}

module "spoke_vpc2" {
  # checkov:skip=CKV_TF_1:commit hashes cannot be used on Terraform registry sources 
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name            = "spoke_2"
  cidr            = var.vpc_data_map.spoke_2.cidr
  private_subnets = var.vpc_data_map.spoke_2.private_subnets
  public_subnets  = var.vpc_data_map.spoke_2.public_subnets
  azs             = local.azs

  providers = {
    aws = aws.spoke_2
  }
}

# Create EC2 instances in the spoke VPCs
module "ec2_instances_spoke1" {
  source           = "./modules/ec2_src"
  vpc_id           = module.spoke_vpc1.vpc_id
  subnet_id        = try(element(module.spoke_vpc1.public_subnets, 0), "")
  src_ec2_count    = var.src_ec2_count
  src_ec2_ssh_cidr = ["${chomp(data.http.my_ip.response_body)}/32"]
  vpc_identifier   = "spoke_vpc1"

  providers = {
    aws = aws.spoke_1
  }
}

module "ec2_instances_spoke2" {
  source           = "./modules/ec2_src"
  vpc_id           = module.spoke_vpc2.vpc_id
  subnet_id        = try(element(module.spoke_vpc2.public_subnets, 0), "")
  src_ec2_count    = var.src_ec2_count
  src_ec2_ssh_cidr = ["${chomp(data.http.my_ip.response_body)}/32"]
  vpc_identifier   = "spoke_vpc2"

  providers = {
    aws = aws.spoke_2
  }
}

# Create Gateway load balancer in the Hub
module "gwlb" {
  source                             = "./modules/gwlb_target"
  name                               = var.name
  load_balancer_type                 = var.load_balancer_type
  subnet_ids                         = module.hub_vpc.public_subnets
  cross_zone_load_balancing_enabled  = var.cross_zone_load_balancing_enabled
  deletion_protection_enabled        = var.deletion_protection_enabled
  vpc_id                             = module.hub_vpc.vpc_id
  vpc_cidr                           = var.vpc_data_map.hub.cidr
  s3_bucket_name                     = format("%s-%s", var.s3_bucket_name, data.aws_caller_identity.current.account_id)
  traffic_mirror_agent_instance_type = var.traffic_mirror_agent_instance_type
  traffic_mirror_asg_max_size        = var.traffic_mirror_asg_max_size
  traffic_mirror_asg_min_size        = var.traffic_mirror_asg_min_size
  traffic_mirror_asg_desired_cap     = var.traffic_mirror_asg_desired_cap
  allowed_principals                 = coalescelist(var.allowed_principals, ["arn:aws:iam::${var.hub_account_id}:root"])
  sns_notify_email                   = var.sns_notify_email
  enable_manual_acceptance           = var.enable_manual_acceptance
  associate_public_ip_address        = var.associate_public_ip_address
  depends_on                         = [module.ec2_instances_spoke1, module.ec2_instances_spoke2]
}

# Add traffic mirroring to spoke VPCs
module "tm_session_spoke1" {
  source                     = "./modules/tm_session"
  gwlb_endpoint_service_name = module.gwlb.gwlb_endpoint_service_name
  gwlb_endpoint_service_type = module.gwlb.gwlb_endpoint_service_type
  spoke_vpc_id               = module.spoke_vpc1.vpc_id
  spoke_subnet_id            = try(element(module.spoke_vpc1.public_subnets, 0), "")
  destination_cidr_block     = var.destination_cidr_block
  source_cidr_block          = var.source_cidr_block
  src_ec2_count              = var.src_ec2_count
  network_interface_ids      = module.ec2_instances_spoke1.ec2_network_interfaces
  providers = {
    aws = aws.spoke_1
  }
}

module "tm_session_spoke2" {
  source                     = "./modules/tm_session"
  gwlb_endpoint_service_name = module.gwlb.gwlb_endpoint_service_name
  gwlb_endpoint_service_type = module.gwlb.gwlb_endpoint_service_type
  spoke_vpc_id               = module.spoke_vpc2.vpc_id
  spoke_subnet_id            = try(element(module.spoke_vpc2.public_subnets, 0), "")
  destination_cidr_block     = var.destination_cidr_block
  source_cidr_block          = var.source_cidr_block
  src_ec2_count              = var.src_ec2_count
  network_interface_ids      = module.ec2_instances_spoke2.ec2_network_interfaces
  providers = {
    aws = aws.spoke_2
  }
}

region                    = "us-west-2"
s3_bucket_name            = "tm-packet-captures-s3"
sns_notify_email          = "sundarsm@amazon.com"
hub_account_id            = "076850539050"
spoke_account_1_id        = "789614100234"
spoke_account_2_id        = "953008266987"
allowed_principals        = ["*"]
terraform_deployment_role = "terraform-deployment-role"
enable_manual_acceptance  = false
source_cidr_block         = "10.0.0.0/8"
destination_cidr_block    = "10.0.0.0/8"
vpc_data_map = {
  hub = {
    name = "packet-capture-hub-vpc"
    cidr = "10.0.0.0/24"

    private_subnets = ["10.0.0.0/26", "10.0.0.64/26"]
    public_subnets  = ["10.0.0.128/26", "10.0.0.192/26"]
    provider_alias  = "hub"
  }
  spoke_1 = {
    name = "packet-capture-spoke-vpc1"
    cidr = "10.1.0.0/24"

    private_subnets = ["10.1.0.0/26", "10.1.0.64/26"]
    public_subnets  = ["10.1.0.128/26", "10.1.0.192/26"]

    provider_alias = "spoke_1"
  }
  spoke_2 = {
    name = "packet-capture-spoke-vpc2"
    cidr = "10.2.0.0/24"

    private_subnets = ["10.2.0.0/26", "10.2.0.64/26"]
    public_subnets  = ["10.2.0.128/26", "10.2.0.192/26"]
    provider_alias  = "spoke_2"
  }
}
provider "aws" {
  region = var.region
  alias  = "hub" # must match a top-level key of vpc_data_map

  default_tags {
    tags = var.default_tags
  }

  assume_role {
    role_arn = "arn:aws:iam::${var.hub_account_id}:role/${var.terraform_deployment_role}"
  }
}


provider "aws" {
  region = var.region
  alias  = "spoke_1" # must match a top-level key of vpc_data_map

  default_tags {
    tags = var.default_tags
  }

  assume_role {
    role_arn = "arn:aws:iam::${var.spoke_account_1_id}:role/${var.terraform_deployment_role}"
  }
}

provider "aws" {
  region = var.region
  alias  = "spoke_2" # must match a top-level key of vpc_data_map

  default_tags {
    tags = var.default_tags
  }

  assume_role {
    role_arn = "arn:aws:iam::${var.spoke_account_2_id}:role/${var.terraform_deployment_role}"
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
data "aws_default_tags" "current" {}

data "aws_iam_policy_document" "ssm_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "agents_user_data" {
  template = file("${path.module}/userdata.tpl")

  vars = {
    TCPDUMP_STORAGE_S3_BUCKET      = "${aws_s3_bucket.this.id}"
    TCPDUMP_RUN_SCRIPT_PATH        = "s3://${aws_s3_bucket.this.id}/${aws_s3_object.run_tcpdump_script.key}"
    TCPDUMP_SVC_ALERTS_SCRIPT_PATH = "s3://${aws_s3_bucket.this.id}/${aws_s3_object.tcpdump_svcalerts_script.key}"
    TCPDUMP_SVC_ALERTS_SNS_ARN     = aws_sns_topic.topic.arn
  }
}

data "aws_ami" "aml2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.2023*.0-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_iam_policy_document" "kms_policy" {
  # checkov:skip=CKV_AWS_109: This key policy is required for the management of the key.
  # checkov:skip=CKV_AWS_111: This key policy is required for the management of the key.
  # checkov:skip=CKV_AWS_356: This key policy is required for the management of the key.
  statement {
    sid       = "AllowRootKeyManagement"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

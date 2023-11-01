#In this module, we will define a GWLB and attach it to a Target Group
resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_91: In a fully integrated environment, access logging should be enabled, but in this standalone example, we don't have a place to send logs
  name = var.name

  load_balancer_type = var.load_balancer_type
  internal           = var.is_lb_internal

  dynamic "subnet_mapping" {
    for_each = var.subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  ## Attributes
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_deletion_protection       = var.deletion_protection_enabled
  drop_invalid_header_fields       = true
}

resource "aws_vpc_endpoint_service" "this" {
  # checkov:skip=CKV_AWS_123:Allow automatic endpoint service acceptance if specified
  acceptance_required        = var.enable_manual_acceptance
  gateway_load_balancer_arns = [aws_lb.this.arn]


  depends_on = [aws_lb.this]
}

resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  for_each                = toset(var.allowed_principals)
  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = each.key
}

resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = "6081"
  protocol = "GENEVE"
  vpc_id   = var.vpc_id

  health_check {
    port     = 80
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "this" {
  # checkov:skip=CKV_AWS_2:Protocol cannot be specified for gateway listeners
  load_balancer_arn = aws_lb.this.arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_kms_key" "this" {
  description         = "tm-packet-capture-kms"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_policy.json
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/packet-capture"
  target_key_id = aws_kms_key.this.key_id
}

# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "this" {
  # checkov:skip=CKV_AWS_144: Bucket is too low-criticality to justify replication costs, only holds scripts
  # checkov:skip=CKV_AWS_18: In an integrated environment with a dedicated access log bucket, access logging should be added to the bucket. However, this module should not create that access logging bucket.
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not necessary, these files will be needed for the whole bucket lifetime
  # checkov:skip=CKV2_AWS_62: Event notifications not necessary, these files are low criticality
  bucket              = var.s3_bucket_name
  object_lock_enabled = true
  force_destroy       = true
}

resource "aws_s3_bucket_policy" "block_s3_http" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.block_s3_http.json
}

data "aws_iam_policy_document" "block_s3_http" {
  statement {
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}


resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_object" "run_tcpdump_script" {
  bucket        = aws_s3_bucket.this.id
  key           = "scripts/run_tcpdump.sh"
  source        = "${path.module}/run_tcpdump.sh"
  etag          = filemd5("${path.module}/run_tcpdump.sh")
  force_destroy = true
}

resource "aws_s3_object" "tcpdump_svcalerts_script" {
  bucket        = aws_s3_bucket.this.id
  key           = "scripts/tm_pktcap_alerts.sh"
  source        = "${path.module}/tm_pktcap_alerts.sh"
  etag          = filemd5("${path.module}/tm_pktcap_alerts.sh")
  force_destroy = true
}

## CREATE TRAFFIC MIRROR TARGETS

resource "aws_launch_template" "traffic_mirror_targets_lt" {
  name                   = "traffic_mirror_targets_tmpl"
  ebs_optimized          = true
  image_id               = data.aws_ami.aml2023.id
  instance_type          = var.traffic_mirror_agent_instance_type
  user_data              = base64encode(data.template_file.agents_user_data.rendered)
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    # The association of public IP address is intentional to simplify automation and doesn't have Ingress to Internet
    associate_public_ip_address = var.associate_public_ip_address # checkov:skip=CKV_AWS_88: Doesn't allow Ingress from Internet
    security_groups             = [aws_security_group.this.id]
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "traffic-mirror-agents"
    }
  }
}

resource "aws_autoscaling_group" "traffic_mirror_agents_asg" {
  name                      = "traffic_mirror_agents_asg"
  vpc_zone_identifier       = var.subnet_ids
  desired_capacity          = var.traffic_mirror_asg_desired_cap
  max_size                  = var.traffic_mirror_asg_max_size
  min_size                  = var.traffic_mirror_asg_min_size
  target_group_arns         = [aws_lb_target_group.this.arn]
  health_check_type         = "EC2"
  wait_for_capacity_timeout = "30m"
  termination_policies      = ["OldestLaunchTemplate"]
  health_check_grace_period = 1800
  default_instance_warmup   = 1800

  launch_template {
    id      = aws_launch_template.traffic_mirror_targets_lt.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(data.aws_default_tags.current.tags, { "purpose" = "traffic-mirroring-agents" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  timeouts {
    delete = "30m"
  }
  depends_on = [
    aws_s3_object.run_tcpdump_script
  ]
}

### IAM CONFIGS ###
resource "aws_iam_policy" "s3_sns" {
  name = "traffic_mirroring_s3_sns_policy" #checkov:skip=CKV_AWS_288: # scripts need access to put files to arbitrary paths
  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards # scripts need access to put files to arbitrary paths
    Statement = [
      {
        Action = [
          "s3:getobject",
          "s3:listbucket",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.this.arn}/*",
          "${aws_s3_bucket.this.arn}"
        ]
      },
      {
        Action = [
          "s3:putobject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.this.arn}/packet-captures/*"
      },
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "${aws_sns_topic.topic.arn}"
      },
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:Decrypt",
          "kms:CreateGrant",
        ]
        Effect   = "Allow"
        Resource = "${aws_kms_key.this.arn}"
      },
    ]
  })
}
resource "aws_iam_role" "this" {
  name               = "traffic_mirror_agents_role"
  assume_role_policy = data.aws_iam_policy_document.ssm_ec2.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    aws_iam_policy.s3_sns.arn,
  ]
}

resource "aws_iam_instance_profile" "this" {
  name = "traffic_mirror_agents_profile"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  name        = "traffic-mirroring-agents-sg"
  description = "Security group for Traffic Mirroring agents"
  vpc_id      = var.vpc_id
  ingress {
    description = "UDP from Traffic Mirror session"
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "TCP traffic for health check"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "Egress to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # The Internet egress is intentional
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }
}
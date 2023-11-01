resource "aws_instance" "ec2_instance" {
  count = var.src_ec2_count

  ami                    = data.aws_ami.aml2023.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.this.name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_instance_sg.id]

  user_data = file("${path.module}/install_apache.sh")

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  monitoring    = true
  ebs_optimized = true

  root_block_device {
    encrypted = true
  }

  disable_api_termination = true

  tags = {
    Name = "tm-packet-capture-s3"
  }
}

resource "aws_security_group" "ec2_instance_sg" {
  name        = "packet-captures-src-ec2-sg"
  description = "EC2 Security Group for Packet Captures Demo"
  vpc_id      = var.vpc_id

  ingress {
    description = "Ingress from EC2 CIDR block"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.src_ec2_ssh_cidr
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

resource "aws_ec2_tag" "ec2_instance_eni" {
  count       = var.src_ec2_count
  resource_id = aws_instance.ec2_instance[count.index].primary_network_interface_id
  key         = "Name"
  value       = "tm-packet-capture-s3"
}

data "aws_iam_policy_document" "ssm_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "traffic_mirror_src_role_${var.vpc_identifier}"
  assume_role_policy = data.aws_iam_policy_document.ssm_ec2.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "this" {
  name = "traffic_mirror_src_profile_${var.vpc_identifier}"
  role = aws_iam_role.this.name

}
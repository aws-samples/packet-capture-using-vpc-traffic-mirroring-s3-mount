data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

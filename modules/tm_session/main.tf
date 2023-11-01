resource "aws_vpc_endpoint" "this" {
  service_name      = var.gwlb_endpoint_service_name
  vpc_endpoint_type = var.gwlb_endpoint_service_type
  vpc_id            = var.spoke_vpc_id
  subnet_ids        = [var.spoke_subnet_id]
}

resource "aws_ec2_traffic_mirror_filter" "this" {
  description = "traffic mirror filter rule id-1"
}

resource "aws_ec2_traffic_mirror_filter_rule" "this" {
  description              = "Ingress Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  destination_cidr_block   = var.destination_cidr_block
  source_cidr_block        = var.source_cidr_block
  rule_number              = 1
  rule_action              = "accept"
  traffic_direction        = "ingress"
  protocol                 = 6 #meaning TCP
}

resource "aws_ec2_traffic_mirror_target" "gwlb_ec2_traffic_mirror_target" {
  gateway_load_balancer_endpoint_id = aws_vpc_endpoint.this.id
}

resource "aws_ec2_traffic_mirror_session" "this" {
  count                    = var.src_ec2_count //length(data.aws_network_interfaces.this.ids) > 0 ? length(data.aws_network_interfaces.this.ids) : 0
  description              = "Traffic Mirroring session"
  network_interface_id     = var.network_interface_ids[count.index]
  session_number           = count.index + 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.gwlb_ec2_traffic_mirror_target.id
}

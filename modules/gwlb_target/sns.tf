resource "aws_sns_topic" "topic" {
  name              = "traffic-mirror-packet-capture-service-alert"
  kms_master_key_id = aws_kms_key.this.key_id
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.sns_notify_email
}
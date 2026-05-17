output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value = aws_sns_topic.alert.arn
}

output "rds_alarm_arn" {
  description = "RDS CPU alarm arn"
  value = aws_cloudwatch_metric_alarm.rds_cpu.arn
}

output "eks_alarm_arn" {
  description = "EKS node CPU alarm"
  value = aws_cloudwatch_metric_alarm.eks_node_cpu.arn
}
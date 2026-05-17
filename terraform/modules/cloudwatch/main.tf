resource "aws_sns_topic" "alert" {
  name = "${var.project_name}-${var.environment}-alerts"
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

}

resource "aws_sns_topic_subscription" "name" {
  topic_arn = aws_sns_topic.alert.arn
  protocol  = "email"
  endpoint  = var.alert_address
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU above 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alert.arn]
  ok_actions          = [aws_sns_topic.alert.arn]
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

}


resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-node-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "EKS node CPU above 85%"
  alarm_actions       = [aws_sns_topic.alert.arn]
  ok_actions          = [aws_sns_topic.alert.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

}

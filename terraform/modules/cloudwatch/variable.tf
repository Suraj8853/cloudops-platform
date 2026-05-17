variable "project_name" {
  type        = string
  description = "name of the project"
}

variable "environment" {
  type        = string
  description = "type of the environment"

}

variable "alert_address" {
  type        = string
  description = "Email address for the alert"

}

/* variable "alb_arn_traffic" {
  description = "ALB ARN suffix for CloudWatch dimensions"
  type        = string
} */

/* variable "alb_5xx_threshold" {
  description = "ALB 5xx error count threshold"
} */

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

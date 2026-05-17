variable "project_name" {
  type = string
  description = "name of the project"
}

variable "environment" {
   type = string
  description = "type of the environment"
}

variable "github_org" {
  description = "Github organization or user name"
  type = string
}

variable "github_repo" {
  description = "Github repository name"
  type = string
}

variable "aws_account_id" {
  description = "AWS account id "
  type = string
}

variable "node_role_name" {
  description = "EKS node group IAM role name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "oidc_id" {
  description = "EKS OIDC provider ID"
  type        = string
}
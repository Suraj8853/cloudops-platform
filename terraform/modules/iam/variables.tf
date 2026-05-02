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
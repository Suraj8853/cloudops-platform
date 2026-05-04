variable "environment" {
description = "environment type for the ecr"
type = string
  
}

variable "project_name" {
  description = "name of the project"
  type = string
}

variable "repositories" {
description = "List of ECR repository names to create"
type = list(string)
default = [ "api","dashboard" ]
}

variable "image_retention_count" {
  description = "Number of images to retain per repository"
  type = number
  default = 10
}

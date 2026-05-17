variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment for the project"
   type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}



variable "vpc_cidr" {
  description = "vpc cidr block"
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids for the cidr"
  type = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.micro"
}

variable "max_allocated_storage" {
  description = "maximumn storage in GB for autoscaling"
  type = number
  default = 100
}

variable "db_name" {
  description = "database name"
  type = string
  default = "cloudops"

}

variable "db_username" {
   description = "database user name"
  type = string
  default = "cloudops_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
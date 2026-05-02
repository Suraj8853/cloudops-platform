variable "vpc_cidr" {
    description = "cidr block for the vpc"
    default = "10.0.0.0/16"
    type = string
  
}
variable "project_name" {
  description = "project name for tagging the resources correctly"
  type = string
}

variable "availability_zones" {
  description = "availabilty_zones to deploy subnets"
  type = list(string)
}

variable "public_subnet_cidrs" {
    description = "public subnets for the instances"
  type = list(string)
}

variable "private_subnet_cidrs" {
    description = "private subnets for the instances"
  type = list(string)
}

variable "environment" {
  description = "environment for this project dev or prod"
  type = string
}
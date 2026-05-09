variable "cluster_name" {
  description = "name of the cluster "
  type = string
}

variable "cluster_version" {
  type = string
  default = "1.29"
}

variable "vpc_id" {
  type = string
  description = "vpc into which cluster will go"
}

variable "private_subnet_ids" {
description = "id of the private subnets for the cluster"
type = list(string)
}

variable "public_subnet_ids" {
description = "id of the private subnets for the cluster"
type = list(string)
}

variable "node_instance_type" {
description = "EC2 instance type for the worker nodes"
type = string
default = "t3.medium"
}

variable "node_max_size" {
description = "Maximum number of the worker nodes"
type = number
default = 5
}

variable "node_min_size" {
description = "Minimum number of the worker nodes"
type = number
default = 2
}

variable "node_desired_size" {
description = "Desired number of the worker nodes"
type = number
default = 2
}

variable "environment" {
  type = string
  description = "environment for the eks cluster"
}



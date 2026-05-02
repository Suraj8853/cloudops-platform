provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "../../modules/vpc"
  environment = "dev"
  project_name = "cloudops"
  public_subnet_cidrs = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24","10.0.4.0/24"]
  availability_zones = ["ap-south-1a","ap-south-1b"]
}
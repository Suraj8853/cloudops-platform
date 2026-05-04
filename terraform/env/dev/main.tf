provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source               = "../../modules/vpc"
  environment          = "dev"
  project_name         = "cloudops"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
}

module "iam" {

  source         = "../../modules/iam"
  project_name   = "cloudops"
  environment    = "dev"
  github_repo    = "cloudops-platform"
  github_org     = "Suraj8853"
  aws_account_id = "599476212737"

}

module "ecr" {
source = "../../modules/ecr"
project_name = "cloudops"
environment = "dev"
image_retention_count = 10
repositories = ["api","dashboard"]


}

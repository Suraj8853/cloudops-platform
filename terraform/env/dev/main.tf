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
  node_role_name = "cloudops-dev-node-role"
  aws_region = "ap-south-1"
 oidc_id        = "30C1634B7074697DE04615E41B6106C0"
  depends_on     = [module.eks]

}

module "ecr" {
source = "../../modules/ecr"
project_name = "cloudops"
environment = "dev"
image_retention_count = 10
repositories = ["api","dashboard"]


}

module "eks" {
  source = "../../modules/eks"
  cluster_name = "cloudops-dev"
  cluster_version = "1.31"
  environment = "dev"
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id = module.vpc.vpc_id
  node_desired_size  = 3
  node_min_size      = 2
  node_max_size      = 5


}


module "cloudwatch" {
  source = "../../modules/cloudwatch"
  project_name = "cloudops"
  cluster_name = "cloudops-dev"
  environment = "dev"
  alert_address = "surajpai8853@gmail.com"
  rds_instance_id = "my-rds"
  depends_on = [ module.eks ]

}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "cloudops/db-password"
}


module "rds" {
source = "../../modules/rds"
project_name = "cloudops"
vpc_id = module.vpc.vpc_id
environment = "dev"
vpc_cidr = module.vpc.vpc_cidr
private_subnet_ids = module.vpc.private_subnet_ids
db_password = data.aws_secretsmanager_secret_version.db_password.secret_string
depends_on = [ module.vpc ]

}




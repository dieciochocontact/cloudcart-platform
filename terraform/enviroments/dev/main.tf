terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source       = "../../modules/networking"
  project_name = "vaultpay-dev"
}

module "compute" {
  source                 = "../../modules/compute"
  project_name           = "vaultpay-dev"
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  key_name               = "claveoreja"
}

module "database" {
  source                  = "../../modules/database"
  project_name            = "vaultpay-dev"
  vpc_id                  = module.networking.vpc_id
  private_data_subnet_ids = module.networking.private_data_subnet_ids
  app_security_group_id   = module.compute.app_security_group_id
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  project_name            = "vaultpay-dev"
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  instance_ids            = module.compute.instance_ids
  alert_email             = "dieciochocontact@gmail.com"
}

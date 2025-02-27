##################################
# AWS Provider
##################################
provider "aws" {
  region = var.aws_region
}

##################################
# Networking Module
##################################
module "networking" {
  source              = "./modules/networking"
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  availability_zones  = var.availability_zones
}

##################################
# Security Module
##################################
module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = module.networking.vpc_cidr
}

##################################
# ALB Module
##################################
module "alb" {
  source              = "./modules/alb"
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id

  app_port           = var.app_port
  health_check_path  = var.health_check_path
}

##################################
# Database Module
##################################
module "database" {
  source             = "./modules/database"
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  
  private_subnet_ids = module.networking.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
  db_engine_version   = "16.3"
  db_port             = 5432

  database_name       = var.database_name
  database_username   = var.database_username
  database_password   = var.database_password

  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
}
##################################
# ECS Module
##################################
module "ecs" {
  source                = "./modules/ecs"
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.networking.vpc_id

  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  app_security_group_id = module.security.app_security_group_id

  ecs_ami_id            = var.ecs_ami_id
  app_port              = var.app_port
  app_count             = var.app_count

  target_group_arn      = module.alb.target_group_arn

  # Pass DB info for the ECS tasks
  db_host = module.database.db_endpoint
  db_name = var.database_name
  db_user = var.database_username

  # This password is stored as an SSM SecureString in the ECS module
  db_password = var.database_password

  # Example toggle to allow S3 read access from tasks
  s3_readonly = true
}

################################################
# High-Level Config
################################################
variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default = "eu-central-1"
}

################################################
# Networking
################################################
variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC (e.g. 10.0.0.0/16)"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs to use for subnets"
}

################################################
# Application / ALB
################################################
variable "app_port" {
  type        = number
  description = "Application port (container and ALB target group port)"
  default     = 8080
}

variable "health_check_path" {
  type        = string
  description = "Path for ALB health checks"
  default     = "/health"
}

variable "app_count" {
  type        = number
  description = "Number of ECS tasks to run"
  default     = 2
}

################################################
# Database
################################################
variable "database_name" {
  type        = string
  description = "Name of the application database"
}

variable "database_username" {
  type        = string
  description = "Database username"
}

variable "database_password" {
  type        = string
  description = "Database password (will be stored in SSM SecureString)"
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class (e.g. db.t3.micro)"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
}

variable "db_engine_version" {
  type        = string
  description = "Engine version for the database (e.g. 14.7 for Postgres)"
}

################################################
# ECS
################################################
variable "ecs_ami_id" {
  type        = string
  description = "Amazon ECS-optimized AMI ID for EC2 launch type"
}
  
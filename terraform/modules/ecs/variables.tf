variable "environment" {
  type        = string
  description = "Environment name (e.g. staging, production)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC in which to deploy ECS"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs (app + ALB go here)"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for the ALB"
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID for ECS instances or tasks"
}

variable "ecs_ami_id" {
  type        = string
  description = "ECS-optimized AMI ID for EC2 launch type"
}

variable "app_port" {
  type        = number
  default     = 8080
  description = "Port on which the application listens"
}

variable "app_count" {
  type        = number
  default     = 2
  description = "Desired number of ECS tasks/instances"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB Target Group for ECS"
}

variable "db_host" {
  type        = string
  description = "Database endpoint/hostname"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_user" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password (will be stored in SSM SecureString)"
}

variable "s3_readonly" {
  type        = bool
  default     = true
  description = "If true, attach a policy granting read-only S3 access to ECS tasks"
}

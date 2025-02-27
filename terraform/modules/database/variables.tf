variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for database"
  type        = string
}

# Engine version can be either '14.7', '15.2', '16.3', etc.
variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.7"
}

variable "db_port" {
  description = "Database port (typically 5432 for Postgres)"
  type        = number
  default     = 5432
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "database_username" {
  description = "Database master username"
  type        = string
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# Optional if you want the VPC ID for some reason (e.g., tags). 
# If not actually used, remove it and don't pass it in the module call.
variable "vpc_id" {
  type        = string
  description = "VPC ID (optional if not used in code)"
  default     = ""
}

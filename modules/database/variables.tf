variable "project_name" {
  description = "Logical project name for resource naming."
  type        = string
}

variable "region" {
  description = "AWS region for database resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the database resources."
  type        = string
}

variable "db_username" {
  description = "Master database username."
  type        = string
}

variable "db_password" {
  description = "Master database password."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Aurora instance class used for writer instances."
  type        = string
  default     = "db.r6g.large"
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "15.4"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database port."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

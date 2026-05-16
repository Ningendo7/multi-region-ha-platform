variable "project_name" {
  description = "Logical project name used in naming resources."
  type        = string
  default     = "ha-system"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for the application domain."
  type        = string
}

variable "app_domain" {
  description = "Primary application domain name, e.g. app.example.com."
  type        = string
}

variable "container_image" {
  description = "Container image used by the Kubernetes deployment."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  description = "Port on which the container listens."
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired replica count for the application deployment (Kubernetes)."
  type        = number
  default     = 2
}

variable "db_username" {
  description = "Master database username."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master database password."
  type        = string
}

variable "db_instance_class" {
  description = "Aurora instance class used for writer/reader instances."
  type        = string
  default     = "db.r6g.large"
}

variable "private_subnet_cidr_blocks" {
  description = "Private subnet CIDR blocks for both availability zones."
  type        = list(string)
  default     = ["10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks for both availability zones."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.8.0/20"]
}

variable "vpc_cidr_block" {
  description = "Primary VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "global_cluster_identifier" {
  description = "Aurora Global Database identifier shared by primary and secondary clusters."
  type        = string
  default     = "ha-system-global"
}

variable "primary_region" {
  description = "Primary AWS region for global resources and database primary write endpoint."
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover traffic."
  type        = string
  default     = "eu-west-1"
}

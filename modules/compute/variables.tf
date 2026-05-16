variable "project_name" {
  description = "Logical project name used for resource naming."
  type        = string
}

variable "region" {
  description = "AWS region where compute resources are deployed."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.28"
}

variable "node_group_name" {
  description = "Name for the managed node group."
  type        = string
  default     = "standard"
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 9
}

variable "node_group_disk_size" {
  description = "Disk size for EKS worker nodes in GB."
  type        = number
  default     = 20
}

variable "container_image" {
  description = "Container image used by the sample application."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_name" {
  description = "Kubernetes container name."
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port exposed inside the container."
  type        = number
  default     = 80
}

variable "node_port" {
  description = "NodePort on worker nodes for ALB target group."
  type        = number
  default     = 30080
}

variable "enable_https" {
  description = "Enable HTTPS listener and ACM certificate."
  type        = bool
  default     = true
}

variable "app_domain" {
  description = "Application DNS name used for ACM certificate validation."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID used for ACM DNS validation."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EKS and ALB deployment."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS node group."
  type        = list(string)
}

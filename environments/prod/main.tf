locals {
  primary_region_label   = replace(var.primary_region, "-", "_")
  secondary_region_label = replace(var.secondary_region, "-", "_")
}

module "network_primary" {
  source = "../../modules/network"

  providers = {
    aws = aws.us_east_1
  }

  region               = var.primary_region
  project_name         = var.project_name
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidr_blocks
  private_subnet_cidrs = var.private_subnet_cidr_blocks
}

module "network_secondary" {
  source = "../../modules/network"

  providers = {
    aws = aws.eu_west_1
  }

  region               = var.secondary_region
  project_name         = var.project_name
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidr_blocks
  private_subnet_cidrs = var.private_subnet_cidr_blocks
}

module "eks_primary" {
  source = "../../modules/compute"

  providers = {
    aws = aws.us_east_1
  }

  project_name       = var.project_name
  region             = var.primary_region
  app_domain         = var.app_domain
  hosted_zone_id     = var.hosted_zone_id
  container_image    = var.container_image
  container_port     = var.container_port
  vpc_id             = module.network_primary.vpc_id
  public_subnet_ids  = module.network_primary.public_subnet_ids
  private_subnet_ids = module.network_primary.private_subnet_ids
}

module "eks_secondary" {
  source = "../../modules/compute"

  providers = {
    aws = aws.eu_west_1
  }

  project_name       = var.project_name
  region             = var.secondary_region
  app_domain         = var.app_domain
  hosted_zone_id     = var.hosted_zone_id
  container_image    = var.container_image
  container_port     = var.container_port
  vpc_id             = module.network_secondary.vpc_id
  public_subnet_ids  = module.network_secondary.public_subnet_ids
  private_subnet_ids = module.network_secondary.private_subnet_ids
}

module "database_primary" {
  source = "../../modules/database"

  providers = {
    aws = aws.us_east_1
  }

  project_name       = var.project_name
  region             = var.primary_region
  vpc_id             = module.network_primary.vpc_id
  private_subnet_ids = module.network_primary.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
}

module "database_secondary" {
  source = "../../modules/database"

  providers = {
    aws = aws.eu_west_1
  }

  project_name       = var.project_name
  region             = var.secondary_region
  vpc_id             = module.network_secondary.vpc_id
  private_subnet_ids = module.network_secondary.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
}

module "global_dns" {
  source = "../../modules/global"
  providers = {
    aws = aws.us_east_1
  }

  project_name   = var.project_name
  hosted_zone_id = var.hosted_zone_id
  app_domain     = var.app_domain

  region_targets = {
    "us-east-1" = {
      dns_name = module.eks_primary.alb_dns_name
      zone_id  = module.eks_primary.alb_zone_id
    }
    "eu-west-1" = {
      dns_name = module.eks_secondary.alb_dns_name
      zone_id  = module.eks_secondary.alb_zone_id
    }
  }
}

output "app_urls" {
  description = "The public URLs for each region behind the global DNS entry."
  value = {
    primary   = module.eks_primary.alb_dns_name
    secondary = module.eks_secondary.alb_dns_name
    global    = var.app_domain
  }
}

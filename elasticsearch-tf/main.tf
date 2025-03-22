provider "aws" {
  region = var.region
}
terraform {
  backend "s3" {
    bucket  = "adil-bucket-es"
    key     = "es-terraform/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "subnets" {
  source                = "./modules/subnets"
  vpc_id                = module.vpc.vpc_id
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
  public_route_table_id = module.vpc.public_route_table_id # Add this line
}

module "nat_gateway" {
  source             = "./modules/nat-gateway"
  public_subnet_id   = module.subnets.public_subnet_ids[0]
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.subnets.private_subnet_ids
}

module "bastion_host" {
  source           = "./modules/bastion-host"
  public_subnet_id = module.subnets.public_subnet_ids[0]
  bastion_sg_id    = module.vpc.bastion_sg_id
  key_name         = var.key_name
}

module "elasticsearch_servers" {
  source             = "./modules/elasticsearch-servers"
  private_subnet_ids = module.subnets.private_subnet_ids
  elasticsearch_sg_id        = module.vpc.elasticsearch_sg_id
  key_name           = var.key_name
}

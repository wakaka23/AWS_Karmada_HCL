terraform {
  required_version = "~>1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.61.0"
    }
  }
  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "osaka"
  region = "ap-northeast-3"
}

module "network" {
  source     = "../../modules/network"
  common     = local.common
  network    = local.network
  peer_cidrs = [local.network_osaka.cidr, local.network_osaka2.cidr]
}

module "network_osaka" {
  source = "../../modules/network"
  providers = {
    aws = aws.osaka
  }
  common     = local.common_osaka
  network    = local.network_osaka
  peer_cidrs = [local.network.cidr]
}

module "network_osaka2" {
  source = "../../modules/network"
  providers = {
    aws = aws.osaka
  }
  common      = local.common_osaka
  network     = local.network_osaka2
  peer_cidrs  = [local.network.cidr]
  name_suffix = "-osaka2"
}

module "ec2" {
  source  = "../../modules/ec2"
  common  = local.common
  network = module.network
}

module "ec2_osaka" {
  source = "../../modules/ec2"
  providers = {
    aws = aws.osaka
  }
  common      = local.common_osaka
  network     = module.network_osaka
  name_suffix = "-osaka"
}

module "ec2_osaka2" {
  source = "../../modules/ec2"
  providers = {
    aws = aws.osaka
  }
  common               = local.common_osaka
  network              = module.network_osaka2
  name_suffix          = "-osaka2"
  worker_instance_type = "g6.xlarge"
}

module "peering" {
  source = "../../modules/peering"
  providers = {
    aws      = aws
    aws.peer = aws.osaka
  }
  common = local.common
  requester = {
    vpc_id          = module.network.vpc_id
    vpc_cidr        = module.network.vpc_cidr
    route_table_ids = module.network.route_table_ids
  }
  accepter = {
    vpc_id          = module.network_osaka.vpc_id
    vpc_cidr        = module.network_osaka.vpc_cidr
    route_table_ids = module.network_osaka.route_table_ids
    region          = "ap-northeast-3"
  }
}

# Peering: Tokyo <-> Osaka cluster #2 only (not connected to the existing Osaka VPC)
module "peering_osaka2" {
  source = "../../modules/peering"
  providers = {
    aws      = aws
    aws.peer = aws.osaka
  }
  common      = local.common
  name_suffix = "-osaka2"
  requester = {
    vpc_id          = module.network.vpc_id
    vpc_cidr        = module.network.vpc_cidr
    route_table_ids = module.network.route_table_ids
  }
  accepter = {
    vpc_id          = module.network_osaka2.vpc_id
    vpc_cidr        = module.network_osaka2.vpc_cidr
    route_table_ids = module.network_osaka2.route_table_ids
    region          = "ap-northeast-3"
  }
}

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

module "network" {
  source = "../../modules/network"
  common = local.common
  network = local.network
}

module "ec2" {
  source = "../../modules/ec2"
  common = local.common
  network = module.network
}
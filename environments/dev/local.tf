data "aws_region" "current" {}
data "aws_region" "osaka" {
  provider = aws.osaka
}
data "aws_caller_identity" "current" {}

locals {
  common = {
    env        = "karmada"
    region     = data.aws_region.current.region
    account_id = data.aws_caller_identity.current.account_id
  }

  common_osaka = {
    env        = "karmada"
    region     = data.aws_region.osaka.region
    account_id = data.aws_caller_identity.current.account_id
  }

  network = {
    cidr = "10.0.0.0/16"
    public_subnets = [
      {
        az   = "a"
        cidr = "10.0.0.0/24"
      },
      {
        az   = "c"
        cidr = "10.0.1.0/24"
      }
    ]
    private_subnets = [
      {
        az   = "a"
        cidr = "10.0.10.0/24"
      },
      {
        az   = "c"
        cidr = "10.0.11.0/24"
      }
    ]
  }

  network_osaka = {
    cidr = "10.1.0.0/16"
    public_subnets = [
      {
        az   = "a"
        cidr = "10.1.0.0/24"
      },
      {
        az   = "c"
        cidr = "10.1.1.0/24"
      }
    ]
    private_subnets = [
      {
        az   = "a"
        cidr = "10.1.10.0/24"
      },
      {
        az   = "c"
        cidr = "10.1.11.0/24"
      }
    ]
  }
}

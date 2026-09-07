variable "common" {
  type = object({
    env    = string
    region = string
  })
}

variable "peer_cidrs" {
  type    = list(string)
  default = []
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "network" {
  type = object({
    cidr = string
    public_subnets = list(object({
      az   = string
      cidr = string
    }))
    private_subnets = list(object({
      az   = string
      cidr = string
    }))
  })
}
variable "common" {
  type = object({
    env = string
    region = string
  })
}

variable "network" {
	type = object({
		cidr = string
    public_subnets = list(object({
			az = string
			cidr = string
		}))
		private_subnets = list(object({
			az = string
			cidr = string
		}))
	})
}
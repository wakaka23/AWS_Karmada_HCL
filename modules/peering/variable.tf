variable "common" {
  type = object({
    env = string
  })
}

# Requester side VPC (associated with the default `aws` provider)
variable "requester" {
  type = object({
    vpc_id          = string
    vpc_cidr        = string
    route_table_ids = list(string)
  })
}

# Accepter side VPC (associated with the `aws.peer` provider)
variable "accepter" {
  type = object({
    vpc_id          = string
    vpc_cidr        = string
    route_table_ids = list(string)
    region          = string
  })
}

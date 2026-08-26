variable "common" {
  type = object({
    env = string
  })
}

variable "network" {
  type = object({
    vpc_id                               = string
    private_subnet_for_control_plane_id  = string
    private_subnet_for_worker_node_id    = string
    security_group_for_control_plane_id  = string
    security_group_for_worker_node_id    = string
  })
}
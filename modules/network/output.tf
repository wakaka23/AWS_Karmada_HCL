output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "route_table_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}

output "private_subnet_for_control_plane_id" {
  value = aws_subnet.private["a"].id
}

output "private_subnet_for_worker_node_id" {
  value = aws_subnet.private["c"].id
}

output "security_group_for_control_plane_id" {
  value = aws_security_group.control_plane.id
}

output "security_group_for_worker_node_id" {
  value = aws_security_group.worker_node.id
}

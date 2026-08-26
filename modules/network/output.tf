output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_for_control_plane_id" {
  value = aws_subnet.private["a"].id
}

output "private_subnet_for_worker_node_id" {
  value = aws_subnet.private["a"].id
}

output "security_group_for_control_plane_id" {
  value = aws_security_group.control_plane.id
}

output "security_group_for_worker_node_id" {
  value = aws_security_group.worker_node.id
}

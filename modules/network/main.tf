########################
# VPC
########################

# Define VPC
resource "aws_vpc" "main" {
  cidr_block           = var.network.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.common.env}-vpc"
  }
}

########################
# Subnet
########################

# Define public subnets
resource "aws_subnet" "public" {
  for_each          = { for s in var.network.public_subnets : s.az => s }
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.common.region}${each.value.az}"
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.common.env}-subnet-public-${each.value.az}"
  }
}

# Define private subnets
resource "aws_subnet" "private" {
  for_each          = { for s in var.network.private_subnets : s.az => s }
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.common.region}${each.value.az}"
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.common.env}-subnet-private-${each.value.az}"
  }
}

########################
# Gateway
########################

# Define Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-igw"
  }
}

# Define NAT Gateway
resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  allocation_id = aws_eip.main[each.key].id
  depends_on = [aws_internet_gateway.main]
  tags = {
    Name = "${var.common.env}-nat-${each.key}"
  }
}

resource "aws_eip" "main" {
  for_each = aws_subnet.public
  domain   = "vpc"
}

########################
# Route Table
########################

# Define route table for public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-rtb-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Define route table for private
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-rtb-private-${each.key}"
  }
}

resource "aws_route" "private" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

########################
# Security Group
########################

# Define security group for ControlPlane
resource "aws_security_group" "control_plane" {
  name   = "${var.common.env}-sg-control-plane"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-sg-control-plane"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_apiserver" {
  security_group_id = aws_security_group.control_plane.id
  ip_protocol = "tcp"
  from_port = 6443
  to_port = 6443
  referenced_security_group_id = aws_security_group.worker_node.id
} 

resource "aws_vpc_security_group_ingress_rule" "control_plane_etcd" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "tcp"
  from_port                    = 2379
  to_port                      = 2380
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kubelet" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_controller_manager" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "tcp"
  from_port                    = 10257
  to_port                      = 10257
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_scheduler" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "tcp"
  from_port                    = 10259
  to_port                      = 10259
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_calico_bgp" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "tcp"
  from_port                    = 179
  to_port                      = 179
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_calico_vxlan" {
  security_group_id            = aws_security_group.control_plane.id
  ip_protocol                  = "udp"
  from_port                    = 4789
  to_port                      = 4789
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_egress_rule" "control_plane" {
  security_group_id = aws_security_group.control_plane.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Define security group for worker node
resource "aws_security_group" "worker_node" {
  name   = "${var.common.env}-sg-worker-node"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-sg-worker-node"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_kubelet" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.control_plane.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_nodeport" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
  referenced_security_group_id = aws_security_group.control_plane.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_calico_bgp_from_control_plane" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "tcp"
  from_port                    = 179
  to_port                      = 179
  referenced_security_group_id = aws_security_group.control_plane.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_calico_bgp_from_worker_node" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "tcp"
  from_port                    = 179
  to_port                      = 179
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_calico_vxlan_from_control_plane" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "udp"
  from_port                    = 4789
  to_port                      = 4789
  referenced_security_group_id = aws_security_group.control_plane.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_calico_vxlan_from_worker_node" {
  security_group_id            = aws_security_group.worker_node.id
  ip_protocol                  = "udp"
  from_port                    = 4789
  to_port                      = 4789
  referenced_security_group_id = aws_security_group.worker_node.id
}

resource "aws_vpc_security_group_egress_rule" "worker_node" {
  security_group_id = aws_security_group.worker_node.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
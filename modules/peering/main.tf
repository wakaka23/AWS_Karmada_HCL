terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.peer]
    }
  }
}

########################
# VPC Peering
########################

# Requester side (default `aws` provider)
resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.requester.vpc_id
  peer_vpc_id = var.accepter.vpc_id
  peer_region = var.accepter.region
  tags = {
    Name = "${var.common.env}-pcx"
  }
}

# Accepter side (`aws.peer` provider). Cross-region peering cannot be
# auto-accepted on the requester, so it is accepted here.
resource "aws_vpc_peering_connection_accepter" "main" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true
  tags = {
    Name = "${var.common.env}-pcx-accepter"
  }
}

########################
# Route
########################

# Requester route tables -> accepter VPC CIDR
resource "aws_route" "requester" {
  count                     = length(var.requester.route_table_ids)
  route_table_id            = var.requester.route_table_ids[count.index]
  destination_cidr_block    = var.accepter.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  depends_on                = [aws_vpc_peering_connection_accepter.main]
}

# Accepter route tables -> requester VPC CIDR
resource "aws_route" "accepter" {
  provider                  = aws.peer
  count                     = length(var.accepter.route_table_ids)
  route_table_id            = var.accepter.route_table_ids[count.index]
  destination_cidr_block    = var.requester.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  depends_on                = [aws_vpc_peering_connection_accepter.main]
}

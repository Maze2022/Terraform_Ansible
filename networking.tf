locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "random_id" "random" {
  byte_length = 2
}


resource "aws_vpc" "maze_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "maze_vpc-${random_id.random.dec}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "maze_internet_gateway" {
  vpc_id = aws_vpc.maze_vpc.id

  tags = {
    Name = "maze_igw-${random_id.random.dec}"
  }
}

resource "aws_route_table" "maze_public_rt" {
  vpc_id = aws_vpc.maze_vpc.id

  tags = {
    Name = "maze_public"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.maze_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.maze_internet_gateway.id
}

resource "aws_default_route_table" "maze_private_rt" {
  default_route_table_id = aws_vpc.maze_vpc.default_route_table_id

  tags = {
    Name = "maze_private"
  }
}

resource "aws_subnet" "maze_public_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.maze_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "maze_public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "maze_private_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.maze_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "maze_private_subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "maze_public_assoc" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.maze_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.maze_public_rt.id
}

resource "aws_security_group" "maze_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.maze_vpc.id
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = [var.access_ip, var.cloud9_ip]
  security_group_id = aws_security_group.maze_sg.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.maze_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" #Specifies any protocol (udp,tcp and icmp)
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.maze_sg.id
}
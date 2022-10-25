resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_hostnames = true
  tags = {
    Name = "eks-${var.cluster_name}"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

resource "aws_route53_zone_association" "assocation" {
  zone_id = var.hosted_zone_id
  vpc_id  = aws_vpc.vpc.id
}

module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.cidr_block_vpc
  networks = [
    {
      name     = "usw2-az1-private"
      new_bits = 8
    },
    {
      name     = "usw2-az2-private"
      new_bits = 8
    },
    {
      name     = "usw2-az3-private"
      new_bits = 8
    },
    {
      name     = "usw2-az4-private"
      new_bits = 8
    },
    {
      name     = "usw2-az1-public"
      new_bits = 8
    },
    {
      name     = "usw2-az2-public"
      new_bits = 8
    },
  ]
}

resource "aws_subnet" "private_subnets" {
  for_each = {
    for name, cidr in module.subnet_addrs.network_cidr_blocks :
  name => cidr if length(regexall(".*private.*", name)) > 0 }
  vpc_id               = aws_vpc.vpc.id
  availability_zone_id = replace(each.key, "-private", "")
  cidr_block           = each.value
  tags = {
    Name                              = "eks-${var.cluster_name}-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "eks-${var.cluster_name}-private"
  }
}

resource "aws_route_table_association" "private_associations" {
  for_each       = aws_subnet.private_subnets
  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}

resource "aws_subnet" "public_subnets" {
  for_each = {
    for name, cidr in module.subnet_addrs.network_cidr_blocks :
  name => cidr if length(regexall(".*public.*", name)) > 0 }
  vpc_id               = aws_vpc.vpc.id
  availability_zone_id = replace(each.key, "-public", "")
  cidr_block           = each.value
  tags = {
    Name                              = "eks-${var.cluster_name}-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

output "private_subnets" {
  value = { for k, v in aws_subnet.private_subnets : k => v.id }
}

output "public_subnets" {
  value = { for k, v in aws_subnet.public_subnets : k => v.id }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "eks-${var.cluster_name}-public"
  }
}

resource "aws_route_table_association" "public_associations" {
  for_each       = aws_subnet.public_subnets
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "eks-${var.cluster_name}"
  }
}

resource "aws_route" "igw" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_eip" "ngw" {
  vpc = true
  tags = {
    Name = "eks-${var.cluster_name}-nat-gateway"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public_subnets["usw2-az1-public"].id
  tags = {
    Name = "eks-${var.cluster_name}"
  }
}

resource "aws_route" "ngw" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
  route_table_id         = aws_route_table.private.id
}

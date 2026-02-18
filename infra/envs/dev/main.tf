locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "dev" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, az in var.azs : az => {
      az   = az
      cidr = var.public_subnet_cidrs[idx]
    }
  }

  vpc_id                  = aws_vpc.dev.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, az in var.azs : az => {
      az   = az
      cidr = var.private_subnet_cidrs[idx]
    }
  }

  vpc_id            = aws_vpc.dev.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-private-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

output "dev_vpc_id" {
  value = aws_vpc.dev.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

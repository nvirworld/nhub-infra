# vpc
resource "aws_vpc" "main" {
  cidr_block           = "10.110.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    "Name" = "${local.project}-vpc-main-${local.env}"
  }
}

# subnet
resource "aws_subnet" "main_public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.110.32.0/20"
  availability_zone       = "${local.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${local.project}-subnet-main-public-a-${local.env}"
  }
}

resource "aws_subnet" "main_public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.110.48.0/20"
  availability_zone       = "${local.aws_region}c"
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${local.project}-subnet-main-public-c-${local.env}"
  }
}


# igw
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${local.project}-igw-main-${local.env}"
  }
}

# route_table
resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    "Name" = "${local.project}-rt-main-public-${local.env}"
  }
}
resource "aws_route_table_association" "main_public_a" {
  subnet_id      = aws_subnet.main_public_a.id
  route_table_id = aws_route_table.main_public.id
}
resource "aws_route_table_association" "main_public_c" {
  subnet_id      = aws_subnet.main_public_c.id
  route_table_id = aws_route_table.main_public.id
}
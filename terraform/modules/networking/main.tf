###################################
# VPC
###################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

###################################
# Public Subnets
###################################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]

  # Public subnets can assign public IPs
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

###################################
# Private Subnets (for DB)
###################################
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]

  # Private subnets should NOT assign public IPs
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

###################################
# Internet Gateway
###################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

###################################
# Public Route Table (for ALB/App)
###################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Public subnets have default route to internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###################################
# Private Route Table (for DB)
###################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No route to internet gateway => truly private
  # (No NAT Gateway route either, since you don't want NAT)
  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
  }
}

# Associate each private subnet with the private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

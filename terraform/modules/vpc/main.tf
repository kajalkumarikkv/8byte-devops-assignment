# VPC
resource "aws_vpc" "main_infra" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main-infra"
  }
}

# Public Subnet 1
resource "aws_subnet" "frontend_subnet_1" {
  vpc_id                  = aws_vpc.main_infra.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "frontend-subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "frontend_subnet_2" {
  vpc_id                  = aws_vpc.main_infra.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "frontend-subnet-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "backend_subnet_1" {
  vpc_id            = aws_vpc.main_infra.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "backend-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "backend_subnet_2" {
  vpc_id            = aws_vpc.main_infra.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "backend-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_infra.id

  tags = {
    Name = "main-infra-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_infra.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main-infra-public-rt"
  }
}

# Public subnet associations
resource "aws_route_table_association" "frontend_1" {
  subnet_id      = aws_subnet.frontend_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "frontend_2" {
  subnet_id      = aws_subnet.frontend_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_infra.id

  tags = {
    Name = "main-infra-private-rt"
  }
}

# Private subnet associations
resource "aws_route_table_association" "backend_1" {
  subnet_id      = aws_subnet.backend_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "backend_2" {
  subnet_id      = aws_subnet.backend_subnet_2.id
  route_table_id = aws_route_table.private.id
}
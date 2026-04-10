data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cicd_range
}

resource "aws_subnet" "main_public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.subnet_cicd_range
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}


resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.public_subnet_rt.id
}
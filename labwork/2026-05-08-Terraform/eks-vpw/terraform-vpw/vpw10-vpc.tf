# Resource-1: Public Subnets
resource "aws_subnet" "public-vpw-eks" {
  vpc_id                  = data.aws_vpc.vpc-vpw.id
  cidr_block              = local.public_subnet_cidr
  availability_zone       = var.aws_availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "vpw-subnet-public-eks"
  })
}

# Resource-2: Private Subnets
# resource "aws_subnet" "private-vpw-eks" {
#   vpc_id            = data.aws_vpc.vpc-vpw.id
#   cidr_block        = local.private_subnet_cidr
#   availability_zone = var.aws_availability_zone
#   tags = merge(var.tags, {
#     Name = "vpw-subnet-private-eks"
#   })
# }

# Resource-3: Public Route Table
resource "aws_route_table" "public_rt-vpw-eks" {
  vpc_id = data.aws_vpc.vpc-vpw.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw-vpw.id
  }
  tags = merge(var.tags, { Name = "vpw-public-rt-eks" })
}

# Resource-4: Public Route Table Associate to Public Subnet
resource "aws_route_table_association" "public_rt_assoc-vpw-eks" {
  subnet_id      = aws_subnet.public-vpw-eks.id
  route_table_id = aws_route_table.public_rt-vpw-eks.id
}

# Resource-5: Private Route Table
# resource "aws_route_table" "private_rt-vpw-eks" {
#   vpc_id = data.aws_vpc.vpc-vpw.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = data.aws_nat_gateway.nat-vpw.id
#   }
#   tags = merge(var.tags, { Name = "vpw-private-rt-eks" })
# }

# Resource-6: Private Route Table Association to Private Subnet
# resource "aws_route_table_association" "private_rt_assoc-vpw-eks" {
#   subnet_id      = aws_subnet.private-vpw-eks.id
#   route_table_id = aws_route_table.private_rt-vpw-eks.id
# }
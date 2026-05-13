# Resource-1: Public Subnets
resource "aws_subnet" "main-public-vpw" {
  vpc_id                  = data.aws_vpc.vpc-vpw.id
  cidr_block              = local.public_subnet_cidr
  availability_zone       = var.aws_availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "vijayalaxmipw-11-pub-subnet"
  })
}

# Resource-2: Private Subnets
# resource "aws_subnet" "private-vpw" {
#   vpc_id            = data.aws_vpc.vpc-vpw.id
#   cidr_block        = local.private_subnet_cidr
#   availability_zone = var.aws_availability_zone
#   tags = merge(var.tags, {
#     Name = "vijayalaxmipw-11-priv-subnet"
#   })
# }

# Resource-3: Public Route Table
# resource "aws_route_table" "public_rt-vpw" {
#  vpc_id = data.aws_vpc.vpc-vpw.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = data.aws_internet_gateway.igw-vpw.id
#   }
#   tags = merge(var.tags, { Name = "vpw-public-rt" })
# }

# Resource-4: Public Route Table Associate to Public Subnet
resource "aws_route_table_association" "main-public_rt_assoc-vpw" {
  subnet_id      = aws_subnet.main-public-vpw.id
  route_table_id = data.aws_route_table.public_rt-vpw.id
}

# resource "aws_eip" "nat-ip" {
#   tags = merge(var.tags, { Name = "${var.environment_name}-nat-eip-vpw" })
# }

# resource "aws_nat_gateway" "nat-vpw" {
#   allocation_id = aws_eip.nat-ip.id
#   subnet_id     = aws_subnet.main-public-vpw.id
#   tags = merge(var.tags, { Name = "${var.environment_name}-nat-vpw" })
# }

# Resource-5: Private Route Table
# resource "aws_route_table" "private_rt-vpw" {
#   vpc_id = data.aws_vpc.vpc-vpw.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat-vpw.id
#   }
#   tags = merge(var.tags, { Name = "vpw-private-rt" })
# }

# Resource-6: Private Route Table Association to Private Subnet
# resource "aws_route_table_association" "private_rt_assoc-vpw" {
#   subnet_id      = aws_subnet.private-vpw.id
#   route_table_id = aws_route_table.private_rt-vpw.id
# }
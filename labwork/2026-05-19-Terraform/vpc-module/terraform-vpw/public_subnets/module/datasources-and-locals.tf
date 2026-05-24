# Data Blocks
data "aws_availability_zones" "az-vpw" {
  state = "available"
}

data "aws_vpc" "vpc-vpw" {
  filter {
    name   = "tag:Name"
    values = ["Bootcamp-vpc-do-not-delete-vpc"]
  }
}

data "aws_internet_gateway" "igw-vpw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.vpc-vpw.id]
  }
}


data "aws_route_table" "public_rt-vpw" {
  filter {
    name   = "tag:Name"
    values = ["Bootcamp-vpc-do-not-delete-public-rt"]
  }
}

# Fetch existing NAT Gateway
#  "aws_nat_gateway" "nat-vpw" {
#   filter {
#     name   = "tag:Name"
#     values = ["Bootcamp-vpc-do-not-delete-nat"]
#   }
# }


# Locals Block
locals {
  azs = data.aws_availability_zones.az-vpw
  public_subnet_cidr = "10.0.21.0/24"
  public_subnet_cidr2 = "10.0.41.0/24"
  private_subnet_cidr = "10.0.121.0/24"
}
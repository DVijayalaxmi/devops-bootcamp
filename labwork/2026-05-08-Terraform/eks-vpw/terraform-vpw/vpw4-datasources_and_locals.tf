data "aws_availability_zones" "azs-vpw" {
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

# Fetch existing NAT Gateway
# data "aws_nat_gateway" "nat-vpw" {
#   filter {
#     name   = "tag:Name"
#     values = ["dev-nat-vpw"]
#   }
# }

# --------------------------------------------------------------------
# Local values used throughout the EKS configuration
# Helps enforce naming consistency and reduce duplication
# --------------------------------------------------------------------
locals {
  # Business division or team name (from variable)
  owners = var.business_division  # Example: "retail"

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name  # Example: "dev"

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}-vpw"  # Example: "retail-dev"

  # Full EKS cluster name used for resource naming and tagging
  eks_cluster_name = "${local.name}-${var.cluster_name}"  # Example: "retail-dev-eksdemo"

  azs = data.aws_availability_zones.azs-vpw.names
  public_subnet_cidr = "10.0.41.0/24"
  private_subnet_cidr = "10.0.141.0/24"
}
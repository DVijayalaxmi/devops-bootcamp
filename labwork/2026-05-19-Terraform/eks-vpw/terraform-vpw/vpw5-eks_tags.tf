# -------------------------------------------------------------------
# Public Subnet Tags for EKS Load Balancer Support
# -------------------------------------------------------------------

resource "aws_ec2_tag" "eks_subnet_tag_public_elb" {
#   for_each    = toset(data.terraform_remote_state.vpc.outputs.public_subnet_id)
  resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "eks_subnet_tag_public_cluster" {
#   for_each    = toset(data.terraform_remote_state.vpc.outputs.public_subnet_id)
  resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "eks_subnet_tag_public_elb-eks" {
#  for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
  resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id-2
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "eks_subnet_tag_public_cluster-eks" {
#   for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
  resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id-2
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

# -------------------------------------------------------------------
# Private Subnet Tags for EKS Internal LoadBalancer Support
# -------------------------------------------------------------------

# resource "aws_ec2_tag" "eks_subnet_tag_public_elb" {
# #  for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
#   resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id
#   key         = "kubernetes.io/role/internal-elb"
#   value       = "1"
# }

# resource "aws_ec2_tag" "eks_subnet_tag_public_cluster" {
# #   for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
#   resource_id = data.terraform_remote_state.vpc.outputs.private_subnet_id
#   key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
#   value       = "shared"
# }
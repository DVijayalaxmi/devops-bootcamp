# --------------------------------------------------------------------
# Reference the Remote State from VPC Project
# --------------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-ap-south-1-0exnf3-vpw"     # Name of the remote S3 bucket where the VPC state is stored
    key    = "vpc/dev/terraform.tfstate"        # Path to the VPC tfstate file within the bucket
    region = var.aws_region                    # Region where the S3 bucket exist
  }
}

# --------------------------------------------------------------------
# Output the VPC ID from the remote VPC state
# --------------------------------------------------------------------
output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}

# --------------------------------------------------------------------
# Output the list of public subnets from the VPC
# --------------------------------------------------------------------
output "public_subnet_id-1" {
  value = data.terraform_remote_state.vpc.outputs.public_subnet_id
}

output "public_subnet_id-2" {
  value = data.terraform_remote_state.vpc.outputs.public_subnet_id-2
}


variable "public-subnets" {
  description = "Tags to apply to EKS and related resources"
  type        = list(string)
  default     = ["<subnet_ids>"]
}



# --------------------------------------------------------------------
# Reference the Remote State from EKS Project
# --------------------------------------------------------------------
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-ap-south-1-0exnf3-vpw"     # Name of the remote S3 bucket where the EKS state is stored
    key    = "eks/dev/terraform.tfstate"        # Path to the EKS tfstate file within the bucket
    region = var.aws_region                    # Region where the S3 bucket exist
  }
}

# --------------------------------------------------------------------
# Output the EKS eks_cluster_name and eks_cluster_id from the remote EKS state
# --------------------------------------------------------------------
output "eks_cluster_name" {
  value = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

output "eks_cluster_id" {
  value = data.terraform_remote_state.eks.outputs.eks_cluster_id
}

# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Remote Backend
  backend "s3" {
    bucket = "tfstate-dev-ap-south-1-0exnf3-vpw"
    key = "eks/dev/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
    use_lockfile = true
  }
}


# Provider Block
provider "aws" {
  region = var.aws_region
}



# Datasource: EKS Cluster Auth 
data "aws_eks_cluster_auth" "cluster-vpw" {
  name = aws_eks_cluster.main.id
}

# HELM Provider
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster-vpw.token
  }
}

# Terraform Kubernetes Provider
provider "kubernetes" {
  host = aws_eks_cluster.main.endpoint 
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster-vpw.token
}
# Datasource: AWS Load Balancer Controller IAM Policy get from aws-load-balancer-controller/ GIT Repo (latest)
data "http" "lbc_iam_policy-vpw" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

# LBC IAM Policy
/*
output "lbc_iam_policy" {
  value = data.http.lbc_iam_policy.response_body
}
*/


# Resource: Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "lbc_iam_policy-vpw" {
  name        = "${local.name}-awsloadbalancercontrolleriampolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy = data.http.lbc_iam_policy-vpw.response_body
}

output "lbc_iam_policy_arn" {
  value = aws_iam_policy.lbc_iam_policy-vpw.arn 
}

# Resource: Create IAM Role 
resource "aws_iam_role" "lbc_iam_role-vpw" {
  name = "${local.name}-lbc-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${local.name}-lbc-iam-role"
    Environment = var.environment_name
    Component   = "AWS Load Balancer Controller"
  }
}

# Associate Load Balanacer Controller IAM Policy to  IAM Role
resource "aws_iam_role_policy_attachment" "lbc_iam_role_policy_attach-vpw" {
  policy_arn = aws_iam_policy.lbc_iam_policy-vpw.arn 
  role       = aws_iam_role.lbc_iam_role-vpw.name
}

output "lbc_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value = aws_iam_role.lbc_iam_role-vpw.arn
}

# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "lbc-vpw" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller-sa-vpw"
  role_arn        = aws_iam_role.lbc_iam_role-vpw.arn
}

# Output: LBC Pod Identity Association ARN
output "lbc_pod_identity_association_arn" {
  description = "AWS Load Balancer Controller Pod Identity Association ARN"
  value       = aws_eks_pod_identity_association.lbc-vpw.association_arn
}


# Install AWS Load Balancer Controller using HELM
resource "helm_release" "loadbalancer_controller-vpw" {
  depends_on = [
    aws_iam_role.lbc_iam_role-vpw,
    aws_eks_node_group.vpw_nodes,
    aws_eks_pod_identity_association.lbc-vpw,
    aws_eks_addon.podidentity-vpw
    ]        

  name       = "aws-load-balancer-controller-vpw"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system" 
  # version  = "1.13.0"         # Recommended in prod, if not specified always uses latest version   

  wait            = true         # Wait for resources to become Ready
  timeout         = 600
  cleanup_on_fail = true 

  set = [
    # Create Service Account via Helm   
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    # Service Account Name 
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller-sa-vpw"
    },
    # EKS Cluster Name
    {
      name  = "clusterName"
      value = "${aws_eks_cluster.main.id}"
    },
    # VPC Id     
    {
      name  = "vpcId"
      value = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
    },
    # AWS Region
    {
      name  = "region"
      value = "${var.aws_region}"
    }     
  ]       
}


# Helm Release Outputs
output "helm_lbc_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.loadbalancer_controller-vpw.metadata
}




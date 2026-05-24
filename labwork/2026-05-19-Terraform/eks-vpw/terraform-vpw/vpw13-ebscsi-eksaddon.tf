# Resource: Create IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_iam_role-vpw" {
  name = "${local.name}-ebs-csi-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${local.name}-ebs-csi-iam-role"
    Environment = var.environment_name
    Component   = "Amazon EBS CSI Driver"
  }
}

# Resource: Attach AWS Managed Policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_managed_policy_attach-vpw" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_iam_role-vpw.name
}

# Output: IAM Role ARN
output "ebs_csi_iam_role_arn" {
  description = "IAM Role ARN for Amazon EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_iam_role-vpw.arn
}



# Resource: EKS Pod Identity Association for EBS CSI Driver
  resource "aws_eks_pod_identity_association" "ebs_csi-vpw" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa-vpw"
  role_arn        = aws_iam_role.ebs_csi_iam_role-vpw.arn
}

# Output: EBS CSI Pod Identity Association ARN
output "ebs_csi_pod_identity_association_arn" {
  description = "EBS CSI Driver Pod Identity Association ARN"
  value       = aws_eks_pod_identity_association.ebs_csi-vpw.association_arn
}



# Datasource: Get the default EBS CSI addon version compatible with EKS version
data "aws_eks_addon_version" "ebs_csi_default-vpw" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
}

# Datasource: Get the latest available EBS CSI addon version
data "aws_eks_addon_version" "ebs_csi_latest-vpw" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# Resource: Install EBS CSI Driver addon
resource "aws_eks_addon" "ebs_csi-vpw" {
  depends_on = [
    aws_iam_role.ebs_csi_iam_role-vpw,
    aws_eks_pod_identity_association.ebs_csi-vpw,
    aws_eks_addon.podidentity-vpw,
    aws_eks_node_group.vpw_nodes
  ]
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi_latest-vpw.version

  #service_account_role_arn    = aws_iam_role.ebs_csi_iam_role-vpw.arn

  pod_identity_association {
    role_arn = aws_iam_role.ebs_csi_iam_role-vpw.arn
    service_account = "ebs-csi-controller-sa-vpw"
    #namespace = "kube-system"
  }

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name        = "${local.name}-aws-ebs-csi-addon"
    Environment = var.environment_name
    Component   = "Amazon EBS CSI Driver"
  }
}


# Outputs
output "ebs_csi_addon_default_version" {
  description = "Default EBS CSI addon version compatible with the EKS cluster version"
  value       = data.aws_eks_addon_version.ebs_csi_default-vpw.version
}

output "ebs_csi_addon_latest_version" {
  description = "Latest available EBS CSI addon version for the current EKS cluster"
  value       = data.aws_eks_addon_version.ebs_csi_latest-vpw.version
}

output "ebs_csi_addon_arn" {
  description = "ARN of the installed EBS CSI addon"
  value       = aws_eks_addon.ebs_csi-vpw.arn
}

output "ebs_csi_addon_id" {
  description = "ID of the installed EBS CSI addon"
  value       = aws_eks_addon.ebs_csi-vpw.id
}

output "ebs_csi_addon_pod_identity_association_arn" {
  description = "EBS CSI Driver Pod Identity Association ARN"
  value       = aws_eks_addon.ebs_csi-vpw.pod_identity_association
}
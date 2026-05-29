# Datasource: To get default EKS addon version compatible with EKS cluster version
data "aws_eks_addon_version" "metrics_server_default-vpw" {
  addon_name         = "metrics-server"
  kubernetes_version = aws_eks_cluster.main.eks_cluster_version
}

# Datasource: To get latest EKS addon version compatible with EKS cluster version
data "aws_eks_addon_version" "metrics_server_latest-vpw" {
  addon_name         = "metrics-server"
  kubernetes_version = aws_eks_cluster.main.eks_cluster_version
  most_recent        = true
}

# EKS Addon: Pod Identity Agent
resource "aws_eks_addon" "metrics_server-vpw" {
  cluster_name                = aws_eks_cluster.main.cluster_id
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  # Use the latest EKS addon version compatible with the cluster's Kubernetes version
  addon_version               = data.aws_eks_addon_version.metrics_server_latest-vpw.version
}


# Outputs
output "metrics_server_eksaddon_default_version" {
  value = data.aws_eks_addon_version.metrics_server_default-vpw.version
}

output "metrics_server_eksaddon_lastest_version" {
  value = data.aws_eks_addon_version.metrics_server_latest-vpw.version
}

output "metrics_server_agent_eksaddon_arn" {
  value = aws_eks_addon.metrics_server-vpw.arn
}  

output "metrics_server_agent_eksaddon_id" {
  value = aws_eks_addon.metrics_server-vpw.id
}

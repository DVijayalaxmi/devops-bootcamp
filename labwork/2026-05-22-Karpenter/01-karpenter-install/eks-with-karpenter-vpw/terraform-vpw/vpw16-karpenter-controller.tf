#Karpenter Controller IAm Role

data "aws_iam_policy_document" "karpenter_controller_assume-vpw" {
  statement {
    sid = "PodIdentity"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller-vpw" {
  name               = "${local.name}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume-vpw.json
  tags               = var.tags
}


# Karpenter Controller IAM Role Outputs
output "karpenter_controller_role_name" {
  description = "IAM role name used by the Karpenter controller"
  value       = aws_iam_role.karpenter_controller-vpw.name
}

output "karpenter_controller_role_arn" {
  description = "IAM role ARN for the Karpenter controller"
  value       = aws_iam_role.karpenter_controller-vpw.arn
}



#Pod Identity Association

resource "aws_eks_pod_identity_association" "karpenter-vpw" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller-vpw.arn
}

# Output
output "karpenter_controller_pod_identity_association" {
  description = "Pod Identity association ID for the Karpenter controller"
  value       = aws_eks_pod_identity_association.karpenter-vpw.id
}



#Karpenter Node IAM Role

data "aws_iam_policy_document" "node_assume-vpw" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_node-vpw" {
  name               = "${local.name}-karpenter-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume-vpw.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_base_policies-vpw" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.karpenter_node-vpw.name
  policy_arn = each.value
}

# outputs
output "karpenter_node_role_name" {
  description = "IAM Role Name used by EC2 nodes launched by Karpenter"
  value       = aws_iam_role.karpenter_node-vpw.name
}

output "karpenter_node_role_arn" {
  description = "IAM Role ARN used by EC2 nodes launched by Karpenter"
  value       = aws_iam_role.karpenter_node-vpw.arn
}

output "karpenter_node_role_unique_id" {
  description = "Unique ID for the Karpenter node IAM role"
  value       = aws_iam_role.karpenter_node-vpw.unique_id
}



#Karpenter Access Entry

resource "aws_eks_access_entry" "karpenter_node_access-vpw" {
  depends_on = [aws_eks_cluster.main]
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.karpenter_node-vpw.arn
  type          = "EC2_LINUX"
}



#Karpenter Helm Install

resource "helm_release" "karpenter-vpw" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.9.0"
  namespace  = "kube-system"
  create_namespace = false

  set = [
    # EKS Cluster Name
    {
    name  = "settings.clusterName"
    value = aws_eks_cluster.main.name
    },
    # EKS Cluster Endpoint
    {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.main.endpoint
    },
    # Interruption Queue
    {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter_interruption-vpw.name
    },    
    # This is the only required one
    {
      name  = "serviceAccount.name"
      value = "karpenter"
    },
    # Karpenter ServiceAccount
    {
      name  = "serviceAccount.create"
      value = "true"
    }
  ]

  # Very Important: Ensure IAM Role + Pod Identity are created BEFORE Helm deploys Karpenter
  depends_on = [
    aws_iam_role.karpenter_controller-vpw,
    aws_iam_policy.karpenter_controller-vpw,
    aws_iam_role_policy_attachment.karpenter_controller_attach-vpw,
    aws_eks_pod_identity_association.karpenter-vpw,
    aws_eks_access_entry.karpenter_node_access-vpw,
    aws_sqs_queue.karpenter_interruption-vpw
  ]  
}

# Outputs
output "karpenter_helm_metadata" {
  description = "Metadata for Karpenter Controller Helm release"
  value       = helm_release.karpenter-vpw.metadata
}



#Karpenter SQS Queue

resource "aws_sqs_queue" "karpenter_interruption-vpw" {
  name                      = aws_eks_cluster.main.name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags = var.tags
}

resource "aws_sqs_queue_policy" "karpenter_interruption-vpw" {
  queue_url = aws_sqs_queue.karpenter_interruption-vpw.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption-vpw.arn
      },
      {
        Sid      = "DenyHTTP"
        Effect   = "Deny"
        Action   = "sqs:*"
        Resource = aws_sqs_queue.karpenter_interruption-vpw.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
        Principal = "*"
      }
    ]
  })
}



#Karpenter EventBridge

# ============================================================================
# File: c6_08_karpenter_eventbridge_rules.tf
# Purpose:
#   EventBridge rules that detect EC2 Spot interruptions, AWS Health events,
#   EC2 rebalance recommendations, and EC2 instance state changes, and send
#   those events to the Karpenter SQS interruption queue.
#
#   This enables Karpenter to gracefully cordon, drain, and replace Spot nodes.
#
# Requirements:
#   - SQS queue must exist (aws_sqs_queue.karpenter_interruption)
#   - IAM policy for Karpenter controller must include sqs:* permissions
#
# Reference:
#   AWS Official Karpenter template:
#   https://github.com/aws/karpenter/
# ============================================================================

locals {
  short_cluster = substr(aws_eks_cluster.main.name, 0, 20)
}

# ----------------------------------------------------------------------------
# AWS Health Events → SQS
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "karpenter_health_event-vpw" {
  name        = "${local.short_cluster}-k-health"
  description = "AWS Health Event → Karpenter Interruption Queue"

  event_pattern = jsonencode({
    source       = ["aws.health"]
    "detail-type" = ["AWS Health Event"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_health_target-vpw" {
  rule      = aws_cloudwatch_event_rule.karpenter_health_event-vpw.name
  target_id = "KarpenterHealthTarget"
  arn       = aws_sqs_queue.karpenter_interruption-vpw.arn
}

# ----------------------------------------------------------------------------
# EC2 Spot Interruption Warning → SQS
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "karpenter_spot_interrupt-vpw" {
  name        = "${local.short_cluster}-k-spot"
  description = "EC2 Spot Interruption Warning → Karpenter SQS Queue"

  event_pattern = jsonencode({
    source       = ["aws.ec2"]
    "detail-type" = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_spot_target-vpw" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interrupt-vpw.name
  target_id = "KarpenterSpotTarget"
  arn       = aws_sqs_queue.karpenter_interruption-vpw.arn
}

# ----------------------------------------------------------------------------
# EC2 Instance Rebalance Recommendation → SQS
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "karpenter_rebalance-vpw" {
  name        = "${local.short_cluster}-k-rebal"
  description = "EC2 Instance Rebalance Recommendation → Karpenter SQS Queue"

  event_pattern = jsonencode({
    source       = ["aws.ec2"]
    "detail-type" = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_rebalance_target-vpw" {
  rule      = aws_cloudwatch_event_rule.karpenter_rebalance-vpw.name
  target_id = "KarpenterRebalanceTarget"
  arn       = aws_sqs_queue.karpenter_interruption-vpw.arn
}

# ----------------------------------------------------------------------------
# EC2 Instance State-change Notification → SQS
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "karpenter_instance_state-vpw" {
  name        = "${local.short_cluster}-k-state"
  description = "EC2 Instance State Change Notification → Karpenter SQS Queue"

  event_pattern = jsonencode({
    source       = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_instance_state_target" {
  rule      = aws_cloudwatch_event_rule.karpenter_instance_state-vpw.name
  target_id = "KarpenterStateTarget"
  arn       = aws_sqs_queue.karpenter_interruption-vpw.arn
}

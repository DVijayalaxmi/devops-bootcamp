# Datasource: IAM Policy Document 
data "aws_iam_policy_document" "assume_role-vpw" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}



# IAM Policy: Allow access to all retailstore-db-secrets
resource "aws_iam_policy" "retailstore_db_secret_policy-vpw" {
  name        = "${local.name}-retailstore-db-secret-policy"
  description = "Allows access to retailstore-db-secret* in AWS Secrets Manager"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:store-secret-vpw*"
      }
    ]
  })
}

# Outputs
output "retailstore_db_secret_policy_arn" {
  description = "IAM Policy ARN for retailstore-db-secret access"
  value       = aws_iam_policy.retailstore_db_secret_policy-vpw.arn
}



#Catalog IAM Role
# IAM Role for Pod Identity (for AWS Secrets Store CSI Driver)
resource "aws_iam_role" "catalog_getsecrets-vpw" {
  name               = "${local.name}-catalog-getsecrets-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role-vpw.json

  tags = {
    Name        = "${local.name}-catalog-getsecrets-role"
    Environment = var.environment_name
    Component   = "AWS Secrets Store CSI Driver ASCP"
  }
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "catalog_db_secret_attach" {
  policy_arn = aws_iam_policy.retailstore_db_secret_policy-vpw.arn
  role       = aws_iam_role.catalog_getsecrets-vpw.name
}

# Outputs
output "catalog_sa_getsecrets_role_arn" {
  description = "IAM Role ARN for Catalog PostgreSQL Get Secrets from AWS Secrets Manager"
  value       = aws_iam_role.catalog_getsecrets-vpw.arn
}



################################################################################
# EKS Pod Identity Association - Catalog MySQL
################################################################################

# This Pod Identity Association allows the Catalog microservice (running as 
# ServiceAccount `catalog`) to assume the IAM role that has access to 
# AWS Secrets Manager.
#
# Purpose:
# - The IAM Role (aws_iam_role.retailstore_csi_role) grants permission to 
#   read the `retailstore-db-secret-1` from AWS Secrets Manager.
# - The Secrets Store CSI Driver uses this association to fetch the credentials 
#   securely and mount them into the Catalog Pod at runtime.
# - These credentials will later be used by the Catalog app to connect to 
#   the **Amazon RDS MySQL Database**.
#
# Without this association, the CSI Driver (or the Pod itself) cannot 
# authenticate with AWS to retrieve secrets.

resource "aws_eks_pod_identity_association" "catalog-vpw" {
  cluster_name    = data.terraform_remote_state.eks.outputs.eks_cluster_name
  namespace       = "default"
  service_account = "catalog-sa-vpw"
  role_arn        = aws_iam_role.catalog_getsecrets-vpw.arn
}


# Output: Catalog MySQL Pod Identity Association ARN
output "catalog_sa_pod_identity_association_arn" {
  description = "Pod Identity Association ARN for Catalog MySQL ServiceAccount (used for AWS Secrets Manager access)"
  value       = aws_eks_pod_identity_association.catalog-vpw.association_arn
}



#Cart IAM Role
# IAM Policy for DynamoDB Access (Cart microservice) - Full Access
resource "aws_iam_policy" "cart_dynamodb_policy-vpw" {
  name        = "${local.name}-cart-dynamodb-policy"
  description = "Allow Cart microservice full access to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTables",
          "dynamodb:ListTagsOfResource"
        ]
        Resource = "*"  # Full access to all DynamoDB resources in all regions
      }
    ]
  })
}

# IAM Role for Cart microservice (Pod Identity Role)
resource "aws_iam_role" "cart_dynamodb_role-vpw" {
  name               = "${local.name}-cart-dynamodb-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role-vpw.json

  tags = {
    Name        = "${local.name}-cart-dynamodb-role"
    Environment = var.environment_name
    Component   = "Cart"
  }
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "cart_dynamodb_policy_attach-vpw" {
  policy_arn = aws_iam_policy.cart_dynamodb_policy-vpw.arn
  role       = aws_iam_role.cart_dynamodb_role-vpw.name
}


# Outputs
output "cart_dynamodb_policy_arn" {
  description = "IAM Policy ARN for Cart microservice DynamoDB access"
  value       = aws_iam_policy.cart_dynamodb_policy-vpw.arn
}

output "cart_dynamodb_role_arn" {
  description = "IAM Role ARN for Cart microservice Pod Identity"
  value       = aws_iam_role.cart_dynamodb_role-vpw.arn
}



# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "cart_pod_identity-vpw" {
  cluster_name    = data.terraform_remote_state.eks.outputs.eks_cluster_name
  namespace       = "default"
  service_account = "carts-sa-vpw"
  role_arn        = aws_iam_role.cart_dynamodb_role-vpw.arn
}

# Output: Cart DynamoDB Pod Identity Association ARN
output "cart_dynamodb_pod_identity_association_arn" {
  description = "Pod Identity Association ARN for Cart DynamoDB ServiceAccount"
  value       = aws_eks_pod_identity_association.cart_pod_identity-vpw.association_arn
}



#Postgres IAM Role
# IAM Role for Pod Identity (for AWS Secrets Store CSI Driver)
resource "aws_iam_role" "orders_postgresql_getsecrets-vpw" {
  name               = "${local.name}-orders-postgresql-getsecrets-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role-vpw.json

  tags = {
    Name        = "${local.name}-orders-postgresql-getsecrets-role"
    Environment = var.environment_name
    Component   = "AWS Secrets Store CSI Driver ASCP"
  }
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "orders_postgresql_db_secret_attach-vpw" {
  policy_arn = aws_iam_policy.retailstore_db_secret_policy-vpw.arn
  role       = aws_iam_role.orders_postgresql_getsecrets-vpw.name
}

# Outputs
output "orders_postgresql_sa_getsecrets_role_arn" {
  description = "IAM Role ARN for Orders PostgreSQL Get Secrets from AWS Secrets Manager"
  value       = aws_iam_role.orders_postgresql_getsecrets-vpw.arn
}



################################################################################
# EKS Pod Identity Association - Orders PostgreSQL
################################################################################

# This Pod Identity Association allows the Orders microservice (running as 
# ServiceAccount `orders`) to assume the IAM role that has access to 
# AWS Secrets Manager.
#
# Purpose:
# - The IAM Role (aws_iam_role.retailstore_orders_csi_role) grants permission to 
#   read the `retailstore-db-secret-1` from AWS Secrets Manager.
# - The Secrets Store CSI Driver uses this association to fetch the credentials 
#   securely and mount them into the Orders Pod at runtime.
# - These credentials will later be used by the Orders app to connect to 
#   the **Amazon RDS PostgreSQL Database**.
#
# Without this association, the CSI Driver (or the Pod itself) cannot 
# authenticate with AWS to retrieve secrets.

resource "aws_eks_pod_identity_association" "orders-vpw" {
  cluster_name    = data.terraform_remote_state.eks.outputs.eks_cluster_name
  namespace       = "default"
  service_account = "orders-sa-vpw"
  role_arn        = aws_iam_role.orders_postgresql_getsecrets-vpw.arn
}

################################################################################
# Outputs
################################################################################

# Output: Orders PostgreSQL Pod Identity Association ARN
output "orders_postgresql_sa_pod_identity_association_arn" {
  description = "Pod Identity Association ARN for Orders PostgreSQL ServiceAccount (used for AWS Secrets Manager access)"
  value       = aws_eks_pod_identity_association.orders-vpw.association_arn
}



#SQS IAM Role
# IAM Policy to Allow Orders Microservice Access to SQS
resource "aws_iam_policy" "orders_sqs_policy-vpw" {
  name        = "${local.name}-orders-sqs-policy"
  description = "Allow Orders microservice to interact with Amazon SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrdersSQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues",
          "sqs:PurgeQueue"
        ]
        Resource = aws_sqs_queue.orders_sqs_queue-vpw.arn
      }
    ]
  })
}

# Attach New SQS Policy to Existing Orders IAM Role
# Note: Reuses the same IAMrole that already has Secrets Manager permissions.
resource "aws_iam_role_policy_attachment" "orders_sqs_policy_attach-vpw" {
  depends_on = [aws_iam_policy.orders_sqs_policy-vpw]
  policy_arn = aws_iam_policy.orders_sqs_policy-vpw.arn
  role       = aws_iam_role.orders_postgresql_getsecrets-vpw.name
}

# Outputs
output "orders_sqs_policy_arn" {
  description = "ARN of the IAM policy granting SQS access for Orders microservice"
  value       = aws_iam_policy.orders_sqs_policy-vpw.arn
}

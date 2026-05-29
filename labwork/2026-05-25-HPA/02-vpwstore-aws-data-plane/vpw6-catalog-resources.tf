# Security Group for RDS MySQL
resource "aws_security_group" "rds_mysql_sg-vpw" {
  name        = "${local.name}-rds-mysql-sg"
  description = "Allow MySQL access from EKS cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow MySQL from EKS cluster security group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      data.terraform_remote_state.eks.outputs.eks_cluster_security_group_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-mysql-sg"
  }
}



# DB Subnet Group (using private subnets from VPC project)
resource "aws_db_subnet_group" "rds_public-vpw" {
  name       = "${local.name}-rds-public-subnets"
  subnet_ids = var.public-subnets

  tags = {
    Name = "${local.name}-rds-public-subnets"
  }
}



# Use existing AWS Secrets Manager Secret (already created manually)
data "aws_secretsmanager_secret" "retailstore_secret-vpw" {
  name = "store-secret-vpw"
}

data "aws_secretsmanager_secret_version" "retailstore_secret_value" {
  secret_id = data.aws_secretsmanager_secret.retailstore_secret-vpw.id
}

locals {
  retailstore_secret_json = jsondecode(data.aws_secretsmanager_secret_version.retailstore_secret_value.secret_string)


}

output "retailstore_secret_json" {
  description = "retailstore_secret_json"
  value       = local.retailstore_secret_json
}

# --------------------------------------------------------------------
# ⚠️ TEMPORARY DEBUG OUTPUTS (NOT RECOMMENDED FOR PRODUCTION)
# --------------------------------------------------------------------
# These outputs are only for verifying that Terraform correctly fetched
# username and password from AWS Secrets Manager. 
# REMOVE or comment out after validation to avoid exposing credentials.
# --------------------------------------------------------------------

output "debug_retailstore_secret_username" {
  description = "⚠️ For testing only: DB username from Secrets Manager"
  value       = data.aws_secretsmanager_secret_version.retailstore_secret_value.username
  sensitive   = true
}

output "debug_retailstore_secret_password" {
  description = "⚠️ For testing only: DB password from Secrets Manager"
  value       = data.aws_secretsmanager_secret_version.retailstore_secret_value.password
  sensitive   = true
}

# If you want to actually see the values just once (for validation), you can run:
# terraform output -json | jq -r '.debug_retailstore_secret_username.value'
# terraform output -json | jq -r '.debug_retailstore_secret_password.value'



# RDS MySQL Database Instance 
resource "aws_db_instance" "catalog_rds-vpw" {
  identifier              = "vpwdb"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "catalogdbvpw"
  username                = local.retailstore_secret_json.username
  password                = local.retailstore_secret_json.password
  db_subnet_group_name    = aws_db_subnet_group.rds_public-vpw.name
  vpc_security_group_ids  = [aws_security_group.rds_mysql_sg-vpw.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  delete_automated_backups = true
  multi_az                = false
  backup_retention_period = 1

  tags = {
    Name = "${local.name}-catalog-rds-mysql"
  }
}


# Outputs
output "catalog_rds_endpoint" {
  description = "RDS endpoint for Catalog microservice"
  value       = aws_db_instance.catalog_rds-vpw.address
}

output "catalog_rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_mysql_sg-vpw.id
}

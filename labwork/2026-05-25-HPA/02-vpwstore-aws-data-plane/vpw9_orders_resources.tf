# Security Group for RDS PostgreSQL
# Allow access only from EKS Cluster security group
resource "aws_security_group" "rds_postgresql_sg-vpw" {
  name        = "${local.name}-rds-postgresql-sg"
  description = "Allow RDS PostgreSQL access from EKS cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "Allow RDS PostgreSQL from EKS Cluster"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [data.terraform_remote_state.eks.outputs.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-postgresql-sg"
  }
}



# RDS PostgreSQL Database Subnet Group for Orders Microservice
resource "aws_db_subnet_group" "rds_postgresql_subnet_group-vpw" {
  name       = "${local.name}-rds-postgresql-subnet-group"
  description = "Subnet group for Orders RDS PostgreSQL"
  subnet_ids  = var.public-subnets

  tags = {
    Name = "${local.name}-rds-postgresql-subnet-group"
  }
}



# RDS PostgreSQL Instance
resource "aws_db_instance" "orders_postgres-vpw" {
  identifier              = "orders-postgres-db-vpw"
  engine                  = "postgres"
  engine_version          = "17.6"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  db_subnet_group_name    = aws_db_subnet_group.rds_postgresql_subnet_group-vpw.name
  vpc_security_group_ids  = [aws_security_group.rds_postgresql_sg-vpw.id]

  db_name                 = "ordersdbvpw"
  username                = local.retailstore_secret_json.username # Getting from c6_03 and AWS Secret Manager secret "retailstore-db-secret-1"
  password                = local.retailstore_secret_json.password # Getting from c6_03 and AWS Secret Manager secret "retailstore-db-secret-1"
  port                    = 5432

  multi_az                = false
  storage_encrypted       = true
  publicly_accessible     = false
  skip_final_snapshot     = true

  backup_retention_period = 7
  deletion_protection     = false

  tags = {
    Name = "${local.name}-orders-rds-postgres"
    Environment = var.environment_name
  }
}

# Outputs for RDS endpoint and credentials
output "orders_rds_postgresql_endpoint" {
  description = "PostgreSQL RDS endpoint for Orders microservice"
  value       = aws_db_instance.orders_postgres-vpw.endpoint
}

output "orders_rds_postgresql_db_name" {
  value       = aws_db_instance.orders_postgres-vpw.db_name
}



# ORDERS - AWS SQS Queue for Asynchronous Order Messaging
resource "aws_sqs_queue" "orders_sqs_queue-vpw" {
  name                        = "${local.name}-orders-queue"
  message_retention_seconds   = 86400     # 1 day
  visibility_timeout_seconds  = 30
  delay_seconds               = 0
  receive_wait_time_seconds   = 10

  tags = {
    Name        = "${local.name}-orders-queue"
    Component   = "Orders"
    Environment = var.environment_name
  }
}

# Outputs
output "orders_sqs_queue_url" {
  description = "SQS Queue URL for Orders microservice"
  value       = aws_sqs_queue.orders_sqs_queue-vpw.url
}

output "orders_sqs_queue_arn" {
  description = "SQS Queue ARN for Orders microservice"
  value       = aws_sqs_queue.orders_sqs_queue-vpw.arn
}

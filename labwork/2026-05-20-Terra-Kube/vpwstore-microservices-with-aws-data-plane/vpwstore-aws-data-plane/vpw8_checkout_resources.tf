resource "aws_security_group" "redis_sg-vpw" {
  name        = "${local.name}-redis-sg"
  description = "Allow EKS cluster to access ElastiCache Redis"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port                = 6379
    to_port                  = 6379
    protocol                 = "tcp"
    security_groups          = [data.terraform_remote_state.eks.outputs.eks_cluster_security_group_id]
    description              = "Allow traffic from EKS cluster SG"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-redis-sg" }
}



# AWS Elastic Cache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group-vpw" {
  name       = "${local.name}-redis-subnets"
  subnet_ids = var.public-subnets
}



# AWS Elastic Cache Redis Cluster
resource "aws_elasticache_cluster" "checkout_redis-vpw" {
  cluster_id           = "${local.name}-checkout-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group-vpw.name
  security_group_ids   = [aws_security_group.redis_sg-vpw.id]
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"

  tags = { Name = "${local.name}-checkout-redis" }
}

# Outputs
output "checkout_redis_endpoint" {
  value = aws_elasticache_cluster.checkout_redis-vpw.cache_nodes[0].address
}
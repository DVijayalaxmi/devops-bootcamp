resource "random_string" "suffix-vpw" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_s3_bucket" "tfstate_bucket-vpw" {
  bucket = "tfstate-${var.environment_name}-${var.aws_region}-${random_string.suffix-vpw.result}-vpw"
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(var.tags, {
    Name        = "tfstate-${var.environment_name}-${var.aws_region}-vpw"
    Environment = var.environment_name
    Project     = "remote-backend-for-devops-real-world-course"
    Purpose     = "terraform-backend"
  })
}

resource "aws_s3_bucket_versioning" "tfstate_versioning-vpw" {
  bucket = aws_s3_bucket.tfstate_bucket-vpw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_encryption-vpw" {
  bucket = aws_s3_bucket.tfstate_bucket-vpw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_block_public-vpw" {
  bucket = aws_s3_bucket.tfstate_bucket-vpw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
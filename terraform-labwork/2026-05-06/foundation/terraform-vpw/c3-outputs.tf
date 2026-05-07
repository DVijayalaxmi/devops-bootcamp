# Output Block
output "s3_bucket_name" {
  value = aws_s3_bucket.s3-vpw.bucket
}

output "s3_bucket_id" {
  value = aws_s3_bucket.s3-vpw.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.s3-vpw.arn
  description = "S3 Bucket ARN"
}

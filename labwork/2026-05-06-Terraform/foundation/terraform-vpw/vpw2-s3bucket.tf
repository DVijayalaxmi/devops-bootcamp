# Resource Block: Random string
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}


# Resource Block: AWS S Bucket
resource "aws_s3_bucket" "s3-vpw" {
  bucket = "vpw-bucket-${random_string.suffix.result}"

  tags = {
    Name        = "VPW bucket"
    Environment = "Dev"
    owner       = "vijayalaxmi.waghmare@einfochips.com"
    enddate     = "31-May-2026"
  }
}

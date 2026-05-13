variable "aws_region" {
  description = "AWS region to deploy resources"
  type = string
  default = "ap-south-1"
}

variable "aws_availability_zone" {
  description = "AWS region to deploy resources"
  type = string
  default = "ap-south-1a"
}

variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Global tags to apply to all resources"
  type        = map(string)
  default     = {
    Terraform = "true"
    owner     = "vijayalaxmi.waghmare@einfochips.com"
    bu        = "ia"
    enddate   = "31-May-2026"
  }
}

data "aws_vpc" "vpc-vpw" {
  filter {
    name   = "tag:Name"
    values = ["Bootcamp-vpc-do-not-delete-vpc"]
  }
}

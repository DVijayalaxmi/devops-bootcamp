output "vpc_id" {
  value       = data.aws_vpc.vpc-vpw.id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       =  aws_subnet.main-public-vpw.id
  description = "List of public subnet IDs"
}

output "private_subnet_id" {
  value       = aws_subnet.private-vpw.id
  description = "List of private subnet IDs"
}

# output "public_rt_id" {
#   value       = aws_route_table.public_rt-vpw.id
#   description = "List of public subnet IDs"
# }

# output "private_rt_id" {
#   value       = aws_route_table.private_rt-vpw.id
#   description = "List of private subnet IDs"
# }

output "availability_zones" {
  value       = data.aws_availability_zones.az-vpw.names
  description = "Map of AZ to Public Subnet ID"
}
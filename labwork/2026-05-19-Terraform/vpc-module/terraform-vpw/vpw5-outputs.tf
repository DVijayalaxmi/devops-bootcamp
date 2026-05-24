output "vpc_id" {
  value       = module.subnets.vpc_id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       =  module.subnets.public_subnet_id
  description = "List of public subnet IDs"
}

output "public_subnet_id-2" {
  value       =  module.subnets.public_subnet_id-2
  description = "List of public subnet IDs"
}

# output "private_subnet_id" {
#   value       = module.subnets.private_subnet_id
#   description = "List of private subnet IDs"
# }

# output "public_rt_id" {
#   value       = aws_route_table.public_rt-vpw.id
#   description = "List of public subnet IDs"
# }

# output "private_rt_id" {
#   value       = aws_route_table.private_rt-vpw.id
#   description = "List of private subnet IDs"
# }

output "availability_zone_map" {
  value       = module.subnets.availability_zones
  description = "Map of AZ to Public Subnet ID"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "instance_private_ips" {
  description = "The private IP addresses of the EC2 instances"
  value       = module.ec2[*].private_ip
}

output "instance_ids" {
  description = "The IDs of the EC2 instances"
  value       = module.ec2[*].instance_id
}

output "ssm_bucket_name" {
  description = "The name of the S3 bucket for SSM session logs"
  value       = module.s3.bucket_name
}

output "bucket_name" {
  description = "Name of the SSM logs S3 bucket"
  value       = aws_s3_bucket.ssm_logs.id
}

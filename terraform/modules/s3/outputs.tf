output "ssm_bucket_name" {
  description = "Name of the SSM logs S3 bucket"
  value       = aws_s3_bucket.ssm_logs.id
}

output "loki_bucket_name" {
  description = "Name of the Loki data S3 bucket"
  value       = aws_s3_bucket.loki_data.id
}

output "tempo_bucket_name" {
  description = "Name of the Tempo data S3 bucket"
  value       = aws_s3_bucket.tempo_data.id
}

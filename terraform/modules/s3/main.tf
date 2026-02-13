resource "aws_s3_bucket" "ssm_logs" {
  bucket        = "${var.project_name}-ssm-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true


  tags = {
    Name    = "${var.project_name}-ssm-logs"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket" "loki_data" {
  bucket        = "${var.project_name}-loki-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-loki-data"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "loki_data" {
  bucket = aws_s3_bucket.loki_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "tempo_data" {
  bucket        = "${var.project_name}-tempo-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-tempo-data"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "tempo_data" {
  bucket = aws_s3_bucket.tempo_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}

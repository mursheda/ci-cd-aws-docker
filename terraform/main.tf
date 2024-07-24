resource "aws_s3_bucket" "buckets" {
  count  = min(length(var.s3_bucket_names), 2)
  bucket = var.s3_bucket_names[count.index]

  tags = {
    Name        = "dev bucket"
    Environment = "Development"
    Owner       = "Mursheda"
  }
}

resource "aws_kms_key" "kmskey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "bucket3" {
  bucket = var.s3_bucket_names[2]
  tags = {
    Team        = "Engineering"
    Environment = "Dev"
    Owner       = "Mursheda"
  }
}
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket3.bucket
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "aws_kms_key" {
  bucket = aws_s3_bucket.bucket3.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kmskey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "bucket4" {
  bucket = "dev-bucket-asdfmm-test"
  
  tags = {
    Team        = "Engineering"
    Environment = "Dev"
    Owner       = "Mursheda"
  }
}

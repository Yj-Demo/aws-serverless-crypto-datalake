resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "bronze" {
  bucket        = "crypto-lake-bronze-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Environment = "dev"
    Project     = "crypto-datalake"
    Layer       = "bronze"
  }
}

output "bronze_bucket_name" {
  value = aws_s3_bucket.bronze.id
}

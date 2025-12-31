# 1. 创建一个专门存放 SQL 查询结果的 S3 桶
resource "aws_s3_bucket" "athena_results" {
  bucket        = "crypto-lake-athena-results-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# 2. 创建 Athena 工作组 (Workgroup)
# 作用：强制把所有查询日志都存到上面那个桶里，方便管理
resource "aws_athena_workgroup" "analysis" {
  name = "crypto-analysis"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}

# --- 1. 创建 Glue 的 IAM 角色 (让 Glue 有权操作) ---
resource "aws_iam_role" "glue_crawler_role" {
  name = "crypto-lake-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

# --- 2. 赋予基础 Glue 权限 (AWS 托管策略) ---
resource "aws_iam_role_policy_attachment" "glue_basic" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# --- 3. 赋予 S3 读写权限 (允许访问我们的 Bronze 桶) ---
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue_s3_access"
  role = aws_iam_role.glue_crawler_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.bronze.arn,             # 桶本身
          "${aws_s3_bucket.bronze.arn}/*"       # 桶内所有文件
        ]
      }
    ]
  })
}

# --- 4. 创建 Glue 数据库 (逻辑数据库) ---
resource "aws_glue_catalog_database" "crypto_db" {
  name = "crypto_lake_db"
}

# --- 5. 创建爬虫 (Crawler) ---
resource "aws_glue_crawler" "bronze_crawler" {
  name          = "crypto-bronze-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.crypto_db.name

  # 告诉爬虫去哪里扫描数据
  s3_target {
    path = "s3://${aws_s3_bucket.bronze.bucket}/raw/"
  }
}

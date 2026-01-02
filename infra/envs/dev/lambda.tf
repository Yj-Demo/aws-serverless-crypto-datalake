# ==========================================
#      Part A: 币价抓取函数 (保持不变)
# ==========================================

# --- 1. 打包 Python 代码 (自动 Zip) ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/ingest_crypto"
  output_path = "${path.module}/ingest_crypto.zip"
}

# --- 2. 创建 IAM 角色 (允许 Lambda 运行) ---
resource "aws_iam_role" "lambda_role" {
  name = "crypto_ingest_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 给角色赋予基础权限 (写日志 + 写 S3)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.bronze.arn}/*"
      }
    ]
  })
}

# --- 3. 创建 Lambda 函数实体 ---
resource "aws_lambda_function" "ingest_function" {
  function_name = "crypto-ingest-daily"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  timeout       = 10

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bronze.id
    }
  }
}

# ==========================================
#      Part B: 新闻分析函数 (已修复大小限制)
# ==========================================

# --- 4. 打包新闻分析器代码 ---
data "archive_file" "news_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/news_analyzer"
  output_path = "${path.module}/news_analyzer.zip"
}

# --- 4.5 新增: 上传代码到 S3 (解决 50MB 限制的核心) ---
resource "aws_s3_object" "lambda_code_upload" {
  bucket = aws_s3_bucket.bronze.id
  key    = "lambda_code/news_analyzer.zip"
  source = data.archive_file.news_zip.output_path
  
  # 使用 etag 确保代码变更时触发重新上传
  etag   = data.archive_file.news_zip.output_base64sha256
}

# --- 5. 新闻 Lambda 的 IAM 角色 ---
resource "aws_iam_role" "news_role" {
  name = "crypto_news_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "news_basic_execution" {
  role       = aws_iam_role.news_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- 6. 新闻分析 Lambda 函数 (指向 S3) ---
resource "aws_lambda_function" "news_analyzer" {
  function_name = "crypto-news-analyzer"
  role          = aws_iam_role.news_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.11"

  # 修改点: 指向 S3 而不是本地文件
  s3_bucket = aws_s3_bucket.bronze.id
  s3_key    = aws_s3_object.lambda_code_upload.key
  
  source_code_hash = data.archive_file.news_zip.output_base64sha256

  timeout     = 60
  memory_size = 256 # 增加内存以支持 AI 处理

  environment {
    variables = {
      DB_HOST     = split(":", aws_db_instance.postgres.endpoint)[0]
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_NAME     = "postgres"
      GEMINI_API_KEY = var.gemini_api_key
    }
  }
}

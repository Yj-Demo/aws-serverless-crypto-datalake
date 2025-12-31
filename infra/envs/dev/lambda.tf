# --- 1. 打包 Python 代码 (自动 Zip) ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/ingest_crypto" # 指向刚才创建的文件夹
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
        Resource = "${aws_s3_bucket.bronze.arn}/*" # 允许写入 Bronze 桶
      }
    ]
  })
}

# --- 3. 创建 Lambda 函数实体 ---
resource "aws_lambda_function" "ingest_function" {
  function_name = "crypto-ingest-daily"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler" # 文件名.函数名
  runtime       = "python3.9"
  timeout       = 10 # 秒

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # 注入环境变量 (把桶名传进去)
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bronze.id
    }
  }
}

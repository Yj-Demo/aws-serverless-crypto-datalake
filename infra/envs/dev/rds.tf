# --- 1. 安全组 (防火墙) ---
# 允许从任何地方访问 5432 端口 (方便我们在本地用 DBeaver/PgAdmin 连接调试)
resource "aws_security_group" "rds_sg" {
  name        = "crypto_rds_sg"
  description = "Allow PostgreSQL access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 生产环境建议只允许特定 IP，但在开发环境为了方便暂设为全开
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. 数据库实例 (RDS PostgreSQL) ---
resource "aws_db_instance" "postgres" {
  identifier          = "crypto-brain-db"
  engine              = "postgres"
  engine_version      = "16.11"          # 使用较新的稳定版本
  instance_class      = "db.t3.micro"   # 免费层级 (Free Tier)
  
  allocated_storage   = 20              # 免费层级包含 20GB
  storage_type        = "gp2"
  
  username            = var.db_username
  password            = var.db_password

  # --- 网络与访问 ---
  publicly_accessible    = true         # 开启公网访问，方便您在本地直接连数据库
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # --- 维护配置 ---
  skip_final_snapshot    = true         # 删除时不要生成快照 (省钱)
  apply_immediately      = true         # 修改配置立即生效
}

# --- 3. 输出数据库连接地址 ---
output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
  description = "Database connection endpoint string"
}

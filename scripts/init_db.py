import psycopg2
from psycopg2 import sql

# --- 配置信息 ---
# 已经帮您去掉了 endpoint 末尾的 :5432
DB_HOST = "crypto-brain-db.cvcy6m8qay8h.ap-southeast-2.rds.amazonaws.com"
DB_PORT = "5432"
DB_NAME = "postgres"
DB_USER = "dbadmin"
DB_PASS = "HolyPass19972486!"

# --- 建表 SQL ---
CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS news_sentiment (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    url TEXT,
    summary TEXT,
    sentiment_score FLOAT,
    sentiment_label TEXT,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

def init_database():
    try:
        # 1. 连接数据库
        print(f"正在连接到: {DB_HOST} ...")
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        conn.autocommit = True 
        cursor = conn.cursor()
        print("连接成功！")

        # 2. 执行建表
        print("正在创建 'news_sentiment' 表...")
        cursor.execute(CREATE_TABLE_SQL)
        print("表结构创建成功！")

        # 3. 插入一条测试数据验证
        print("插入一条测试数据...")
        cursor.execute("""
            INSERT INTO news_sentiment (title, sentiment_score, sentiment_label)
            VALUES ('Bitcoin hits $100k!', 0.99, 'Bullish');
        """)
        print("测试数据插入成功！")

        cursor.close()
        conn.close()
        print("\n数据库初始化完成！您的 CryptoBrain 已准备就绪。")

    except Exception as e:
        print(f"\n发生错误: {e}")
        print("提示：请检查 Security Group 是否允许了您的 IP，以及密码是否正确。")

if __name__ == "__main__":
    init_database()

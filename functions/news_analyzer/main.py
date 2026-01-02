import json
import os
import psycopg2
import feedparser
import google.generativeai as genai
from datetime import datetime
import time

# --- 配置信息 ---
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = os.environ.get('DB_NAME', 'postgres')
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

RSS_URL = "https://cointelegraph.com/rss"

# 配置 Gemini
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=5432
    )

def analyze_sentiment(text):
    """调用 Gemini API 分析情感"""
    if not GEMINI_API_KEY:
        print("[WARN] 未找到 Gemini API Key，跳过分析")
        return 0.0, "Neutral"
    
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt = f"""
        Analyze the sentiment of the following crypto news headline for a crypto investor.
        
        Headline: "{text}"
        
        Return ONLY a JSON object with two fields:
        1. "score": a float between -1.0 (very negative) and 1.0 (very positive).
        2. "label": a string (Bullish, Bearish, or Neutral).
        
        Do not output markdown code blocks. Just the JSON string.
        """
        
        response = model.generate_content(prompt)
        # 清理可能存在的 markdown 标记
        clean_text = response.text.replace('```json', '').replace('```', '').strip()
        result = json.loads(clean_text)
        
        return result.get('score', 0.0), result.get('label', 'Neutral')
        
    except Exception as e:
        print(f"[ERROR] AI 分析失败: {e}")
        return 0.0, "Error"

def lambda_handler(event, context):
    conn = None
    try:
        print("[INFO] 1. 获取 RSS 新闻...")
        feed = feedparser.parse(RSS_URL)
        print(f"       获取到 {len(feed.entries)} 条")

        print("[INFO] 2. 连接数据库...")
        conn = get_db_connection()
        cur = conn.cursor()

        new_count = 0
        
        for entry in feed.entries:
            link = entry.link
            title = entry.title
            summary = entry.summary if 'summary' in entry else ''
            
            # 检查重复
            cur.execute("SELECT id FROM news_sentiment WHERE url = %s", (link,))
            if cur.fetchone():
                continue

            # --- AI 分析 ---
            print(f"[AI] 正在分析: {title[:30]}...")
            sentiment_score, sentiment_label = analyze_sentiment(title)
            
            # 时间处理
            published_parsed = entry.get('published_parsed')
            if published_parsed:
                published_at = datetime.fromtimestamp(time.mktime(published_parsed))
            else:
                published_at = datetime.now()

            # 入库
            insert_sql = """
                INSERT INTO news_sentiment 
                (title, url, summary, sentiment_score, sentiment_label, published_at)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            cur.execute(insert_sql, (title, link, summary, sentiment_score, sentiment_label, published_at))
            new_count += 1
            
            # 为了避免触发 API 速率限制，这里简单休眠一下 (免费版每分钟限制 15 次请求)
            time.sleep(1) 

        conn.commit()
        cur.close()
        
        msg = f"成功入库 {new_count} 条新闻，并已完成 AI 分析！"
        print(f"[SUCCESS] {msg}")
        return {'statusCode': 200, 'body': json.dumps(msg)}

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        if conn: conn.rollback()
        return {'statusCode': 500, 'body': json.dumps(str(e))}
    finally:
        if conn: conn.close()

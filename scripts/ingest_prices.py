import boto3
import requests
import json
import datetime

# 🚨 请务必替换为您刚才 Terraform 输出的真实桶名！
BUCKET_NAME = "crypto-lake-bronze-f94ba7a6" 

def fetch_crypto_data():
    """从 CoinGecko API 获取比特币和以太坊价格"""
    url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_last_updated_at=true"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching data: {e}")
        return None

def upload_to_s3(data, bucket):
    """将数据上传到 S3，按日期分区"""
    s3 = boto3.client('s3')
    
    # 生成分区路径: raw/2025-12-23/
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    timestamp = datetime.datetime.now().strftime('%H-%M-%S')
    file_name = f"raw/{today}/prices_{timestamp}.json"
    
    try:
        s3.put_object(
            Bucket=bucket,
            Key=file_name,
            Body=json.dumps(data),
            ContentType='application/json'
        )
        print(f"✅ Success! Data uploaded to: s3://{bucket}/{file_name}")
    except Exception as e:
        print(f"❌ Error uploading to S3: {e}")

if __name__ == "__main__":
    print(f"Fetching crypto prices...")
    data = fetch_crypto_data()
    
    if data:
        print(f"Data received: {data}")
        upload_to_s3(data, BUCKET_NAME)

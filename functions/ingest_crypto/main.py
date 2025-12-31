import boto3
import requests 
import json
import datetime
import os

# 从环境变量获取桶名
BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    print("🚀 Starting ingestion with Requests...")
    
    url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_last_updated_at=true"
    
    try:
        # 使用 requests，代码更简洁、更可读
        response = requests.get(url, timeout=5)
        response.raise_for_status() # 如果是 4xx/5xx 直接报错
        
        data = response.json()
        print(f"✅ Data fetched: {data}")
        
        upload_to_s3(data)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Ingestion Success')
        }
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise e

def upload_to_s3(data):
    s3 = boto3.client('s3')
    
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    timestamp = datetime.datetime.now().strftime('%H-%M-%S')
    file_name = f"raw/{today}/lambda_prices_{timestamp}.json"
    
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=file_name,
        Body=json.dumps(data),
        ContentType='application/json'
    )
    print(f"✅ Uploaded to s3://{BUCKET_NAME}/{file_name}")

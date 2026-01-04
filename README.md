# AWS Serverless Crypto Data Lake & AI Sentiment Analysis Platform

![AWS](https://img.shields.io/badge/AWS-Serverless-orange?style=flat&logo=amazon-aws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?style=flat&logo=terraform)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=flat&logo=python)
![Gemini AI](https://img.shields.io/badge/AI-Google%20Gemini%202.5-4285F4?style=flat&logo=google)
![Grafana](https://img.shields.io/badge/Viz-Grafana-F46800?style=flat&logo=grafana)

> **A fully automated, serverless data engineering pipeline that correlates cryptocurrency price volatility with AI-driven news sentiment analysis.**

## 📖 Project Overview

This project implements a modern **Serverless Data Lake** architecture on AWS to solve a classic quantitative finance problem: *Does news sentiment predict market price action?*

Instead of traditional keyword matching, this system leverages **Generative AI (Google Gemini LLM)** to "read" and understand crypto news, assigning a quantitative sentiment score (Bullish/Bearish) to unstructured text. The data is processed via automated ETL pipelines and visualized in real-time to identify Alpha signals.

### Key Features
* **🤖 AI-Powered Analysis:** Uses **Google Gemini 2.5 Flash** to perform semantic sentiment analysis on unstructured news data.
* **☁️ Serverless Architecture:** Fully deployed on AWS Lambda & EventBridge, costing nearly **$0/month** to operate.
* **🏗️ Infrastructure as Code:** 100% of the infrastructure (Compute, Database, Triggers) is provisioned via **Terraform**.
* **🔄 Dual ETL Pipelines:**
    * **Pipeline A:** Real-time asset price ingestion (BTC/ETH) from CoinGecko.
    * **Pipeline B:** RSS news scraping + LLM inference + Deduplication logic.
* **📊 Professional Visualization:** Grafana dashboard featuring Moving Average (MA) trend lines, Zero-Line crossovers, and volume analysis.

---

## 🏗️ Architecture

```mermaid
graph TD
    %% 定义样式类 (AWS 官方配色)
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:white;
    classDef db fill:#3B48CC,stroke:#232F3E,stroke-width:2px,color:white;
    classDef ext fill:#E0E0E0,stroke:#333,stroke-width:2px,color:black;
    classDef viz fill:#F46800,stroke:#333,stroke-width:2px,color:white;

    subgraph "AWS Cloud (ap-southeast-2)"
        direction TB
        EB[⏱️ EventBridge Scheduler]:::aws
        L_Price[λ Lambda: Ingest Prices]:::aws
        L_News[λ Lambda: AI News Analyzer]:::aws
        RDS[("🛢️ Amazon RDS (PostgreSQL)")]:::db
    end

    subgraph "External World"
        RSS[📰 News Feeds (RSS)]:::ext
        AI[🧠 Google Gemini API]:::ext
    end
    
    Grafana[📊 Grafana Dashboard]:::viz

    %% 连线逻辑
    EB -->|Hourly Trigger| L_Price
    EB -->|Hourly Trigger| L_News
    
    L_Price -->|1. Write Price| RDS
    
    L_News -->|2. Fetch Data| RSS
    L_News -->|3. Inference| AI
    AI -.->|Returns Score| L_News
    L_News -->|4. Write Sentiment| RDS
    
    RDS -->|5. SQL Query| Grafana

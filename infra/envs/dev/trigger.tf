# --- 1. 定义定时规则 (闹钟) ---
# rate(1 hour) 表示每小时触发一次
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "crypto-ingest-hourly"
  description         = "Trigger crypto lambda every hour"
  schedule_expression = "rate(1 hour)"
}

# --- 2. 绑定目标 (告诉闹钟叫醒谁) ---
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.ingest_function.arn
}

# --- 3. 授予权限 (通行证) ---
# 关键：AWS 默认禁止服务间互相调用，必须显式允许 EventBridge 触发 Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# 4. 绑定第二个目标 (把新闻函数也连到闹钟上)
resource "aws_cloudwatch_event_target" "trigger_news" {
  # 指向现有的那个规则 (resource名是 "schedule")
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "TriggerNewsAnalyzer"
  arn       = aws_lambda_function.news_analyzer.arn
}

# 5. 授予第二个通行证 (允许闹钟调用新闻函数)
resource "aws_lambda_permission" "allow_cloudwatch_news" {
  statement_id  = "AllowExecutionFromEventBridgeNews"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.news_analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

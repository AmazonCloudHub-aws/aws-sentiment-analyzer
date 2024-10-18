# main.tf

provider "aws" {
  region = var.aws_region
}

# S3 bucket for storing sentiment analysis data
resource "aws_s3_bucket" "sentiment_data" {
  bucket = "${var.project_name}-sentiment-data"
  acl    = "private"

  tags = {
    Name        = "${var.project_name} Sentiment Data"
    Environment = var.environment
  }
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access S3 and Comprehend
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "comprehend:DetectSentiment"
        ]
        Resource = [
          aws_s3_bucket.sentiment_data.arn,
          "${aws_s3_bucket.sentiment_data.arn}/*",
          "arn:aws:comprehend:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function for Reddit data collection
resource "aws_lambda_function" "reddit_collector" {
  filename      = "lambda/reddit_collector.zip"
  function_name = "${var.project_name}-reddit-collector"
  role          = aws_iam_role.lambda_role.arn
  handler       = "reddit_collector.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.sentiment_data.id
    }
  }
}

# Lambda function for sentiment analysis
resource "aws_lambda_function" "sentiment_analyzer" {
  filename      = "lambda/sentiment_analyzer.zip"
  function_name = "${var.project_name}-sentiment-analyzer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "sentiment_analyzer.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.sentiment_data.id
    }
  }
}

# CloudWatch Event Rule to trigger Reddit collector Lambda
resource "aws_cloudwatch_event_rule" "reddit_collector_schedule" {
  name                = "${var.project_name}-reddit-collector-schedule"
  description         = "Schedule for Reddit data collection"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "reddit_collector_target" {
  rule      = aws_cloudwatch_event_rule.reddit_collector_schedule.name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.reddit_collector.arn
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "reddit_collector_logs" {
  name              = "/aws/lambda/${aws_lambda_function.reddit_collector.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sentiment_analyzer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.sentiment_analyzer.function_name}"
  retention_in_days = 14
}

# Data source to get AWS account ID
data "aws_caller_identity" "current" {}


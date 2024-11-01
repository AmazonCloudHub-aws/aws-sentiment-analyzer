# main.tf

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "sentiment_data" {
  bucket = "${var.project_name}-sentiment-data"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

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
          "arn:aws:s3:::amazon-reviews-pds",
          "arn:aws:s3:::amazon-reviews-pds/*"
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

resource "aws_lambda_function" "reddit_collector" {
  filename      = abspath("${path.module}/lambda/reddit_collector.zip")
  function_name = "${var.project_name}-reddit-collector"
  role          = aws_iam_role.lambda_role.arn
  handler       = "reddit_collector.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      S3_BUCKET         = aws_s3_bucket.sentiment_data.id
      DATA_FOLDER       = "raw_data/reddit/"  # Store Reddit data in raw_data/reddit/
      REDDIT_CLIENT_ID  = var.reddit_client_id
      REDDIT_CLIENT_SECRET = var.reddit_client_secret
    }
  }
}


resource "aws_lambda_function" "sentiment_analyzer" {
  filename      = abspath("${path.module}/lambda/sentiment_analyzer.zip")
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

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${var.project_name}-daily-trigger"
  description         = "Triggers data collection and analysis daily"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_reddit_collector" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "RedditCollector"
  arn       = aws_lambda_function.reddit_collector.arn
}



resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.sentiment_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.sentiment_analyzer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw_data/"  # Trigger only for new objects in raw_data folder
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sentiment_analyzer.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.sentiment_data.arn
}

resource "aws_comprehend_document_classifier" "custom_classifier" {
  name = "${var.project_name}-classifier"
  data_access_role_arn = aws_iam_role.comprehend_role.arn

  input_data_config {
    s3_uri = "s3://${aws_s3_bucket.sentiment_data.id}/processed_data/"
  }

  language_code = "en"

  timeouts {
    create = "4h"
    update = "4h"
    delete = "2h"
  }
}

resource "aws_iam_role" "comprehend_role" {
  name = "${var.project_name}-comprehend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "comprehend.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "comprehend_s3_access_policy" {
  name = "${var.project_name}-comprehend-s3-access"
  role = aws_iam_role.comprehend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.sentiment_data.arn}",
          "${aws_s3_bucket.sentiment_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "comprehend_s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.comprehend_role.name
}

resource "aws_quicksight_data_source" "s3_source" {
  data_source_id = "${var.project_name}-s3-source"
  aws_account_id = data.aws_caller_identity.current.account_id
  name = "Sentiment Analysis S3 Data Source"
  type = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = aws_s3_bucket.sentiment_data.id
        key    = aws_s3_object.quicksight_manifest.key
      }
    }
  }
}

resource "aws_s3_object" "quicksight_manifest" {
  bucket  = aws_s3_bucket.sentiment_data.id
  key     = "quicksight-manifest.json"
  content = jsonencode({
    fileLocations = [
      { URIPrefixes = ["s3://${aws_s3_bucket.sentiment_data.id}/processed_data/"] }
    ],
    globalUploadSettings = { format = "CSV" }
  })
}

data "aws_caller_identity" "current" {}

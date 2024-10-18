# outputs.tf

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.sentiment_data.id
}

output "reddit_collector_lambda_arn" {
  description = "The ARN of the Reddit collector Lambda function"
  value       = aws_lambda_function.reddit_collector.arn
}

output "sentiment_analyzer_lambda_arn" {
  description = "The ARN of the sentiment analyzer Lambda function"
  value       = aws_lambda_function.sentiment_analyzer.arn
}

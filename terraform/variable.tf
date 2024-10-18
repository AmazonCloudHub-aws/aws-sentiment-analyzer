# variables.tf

variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "project_name" {
  description = "The name of the project"
  default     = "sentiment-analysis"
}

variable "environment" {
  description = "The deployment environment"
  default     = "dev"
}


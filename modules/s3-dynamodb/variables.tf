variable "bucket" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "table" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

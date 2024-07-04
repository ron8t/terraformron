terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    key            = "infra/terraformstatefile"
    bucket         = "fusisoft-terraform-backend-bucket"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locking"
  }
}

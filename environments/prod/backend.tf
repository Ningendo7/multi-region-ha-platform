terraform {
  backend "s3" {
    bucket         = "ha-system-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ha-system-tf-lock"
    encrypt        = true
  }
}

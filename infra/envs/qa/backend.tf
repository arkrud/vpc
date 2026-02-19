terraform {
  backend "s3" {
    bucket         = "terraform-state-arkadiy-2026"
    key            = "tfstate/qa/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
terraform {
  backend "s3" {
    bucket         = "cloudcart-terraform-state-101551113442"
    key            = "cloudcart-platform/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloudcart-terraform-locks"
    encrypt        = true
  }
}
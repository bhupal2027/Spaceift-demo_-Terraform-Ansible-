terraform {
  backend "s3" {
    bucket         = "bhupal-spacelift-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

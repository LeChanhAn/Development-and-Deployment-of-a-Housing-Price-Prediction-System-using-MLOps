terraform {
  backend "s3" {
    bucket         = "dacn-project-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "dacn-terraform-state-lock"
  }
}
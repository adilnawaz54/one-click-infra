terraform {
  backend "s3" {
    bucket  = "adil-bucket-es"
    key     = "elasticsearch/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

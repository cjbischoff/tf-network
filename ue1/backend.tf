terraform {
  backend "s3" {
    bucket = "sliplabio-ue1-terraform-remote-state"
    key    = "tf-network/ue1/terraform.tfstate"
    region = "us-east-1"
  }
}

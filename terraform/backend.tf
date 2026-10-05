terraform {

  backend "s3" {
    bucket = "terraform54544"
    key    = "terraform-state"
    region = "us-east-1"

  }
}
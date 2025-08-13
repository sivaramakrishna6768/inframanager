terraform {
  backend "s3" {
    bucket         = "inframanager-tfstate-sivaramakrishna6768"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "inframanager-tf-locks"
    encrypt        = true
  }
}

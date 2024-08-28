terraform {
  backend "s3" {
    bucket = "cica-infra-terraform-state"
    key    = "lambda-kofax-clearup-smb/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "cica-infra-terraform-state-locks"
    encrypt        = true
  }
}

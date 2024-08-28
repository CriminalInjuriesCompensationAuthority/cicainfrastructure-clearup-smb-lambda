provider "aws" {
  region                   = "eu-west-2"
  shared_credentials_files = ["~/.aws/credentials"]
  ## Comment out assume_role and uncomment profile to run terraform plan locally ##

  profile = var.profile[var.environment]
  # assume_role {
  #   role_arn = var.assumed_role
  # }
  default_tags {
    tags = {
      Name        = "ClearUp-SMB-Lambda"
      Environment = var.environment
      Code        = "github.com/CriminalInjuriesCompensationAuthority/cicainfrastructure-clearup-smb-lambda"
    }
  }
}

provider "aws"{
  alias = "sharedservices"
  region = "eu-west-2"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = var.profile["SharedServices"]
}



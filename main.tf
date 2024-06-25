terraform {
  required_version = ">= 1.5.4"

  required_providers {
    aws = ">= 5.19.0"
  }

  backend "s3" {
    profile = "nhub"
    bucket  = "nhub-s3-terraform-prod"
    key     = "prod.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "nhub"
}

provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "nhub"
}


locals {
  project                 = "nhub"
  env                     = "prod"
  aws_account_id          = "797127116500"
  aws_region              = "ap-northeast-2"
  acm_nhub_io_arn         = "arn:aws:acm:${local.aws_region}:${local.aws_account_id}:certificate/f621ef21-73ca-435b-be6b-e812759d9d6a"
  acm_nhub_io_useast1_arn = "arn:aws:acm:us-east-1:${local.aws_account_id}:certificate/9eb5fa19-3a48-4808-9d72-2959d761128e"
  github_connection_arn   = "arn:aws:codestar-connections:${local.aws_region}:${local.aws_account_id}:connection/9c2dee1e-b4e2-48f1-abb0-8f8a6625cad2"
}
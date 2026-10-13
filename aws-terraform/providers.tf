terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
 # backend "s3" {
 #   bucket         = "homelab-terraform-state-bkp-1409829381"
 #   key            = "hybrid-infra/terraform.tfstate"
 #   region         = "eu-central-1"
 #   use_lockfile = true
 # }
}

provider "aws" {
  region = "eu-central-1"
}
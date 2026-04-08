terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Owner   = var.Owner
      Name    = var.Name
      Project = var.Project
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "vasu-task-5-tfstate"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile = true
    encrypt        = true
  }
}
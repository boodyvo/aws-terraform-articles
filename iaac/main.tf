terraform {
  required_version = ">= 1.2.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
  }
}

provider aws {
  region  = "us-east-1"
  profile = "go-example"

  default_tags {
    tags = {
      project: "go-example"
    }
  }
}

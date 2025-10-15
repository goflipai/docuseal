data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}

data "aws_ecr_authorization_token" "token" {}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "networking/terraform.tfstate"
  }
}

data "terraform_remote_state" "lbs" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "lbs/terraform.tfstate"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "eks/terraform.tfstate"
  }
}

data "terraform_remote_state" "cache" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "api-cache/terraform.tfstate"
  }
}

data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "api-secrets/terraform.tfstate"
  }
}

data "terraform_remote_state" "infra_apps" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "apps/terraform.tfstate"
  }
}

data "aws_ecr_images" "this" {
  repository_name = local.repo_name
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid = "S3Access"
    actions = [
      "s3:HeadBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
      "s3:PutObjectAcl",
      "s3:GetObjectAcl"
    ]
    resources = [
      "arn:${local.partition}:s3:::${local.env}-*",
      "arn:${local.partition}:s3:::${local.env}-*/*",
    ]
  }
}

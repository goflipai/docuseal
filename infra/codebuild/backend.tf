terraform {
  backend "s3" {
    profile      = "flip"
    bucket       = "goflipai-terraform-state-shared"
    region       = "us-gov-west-1"
    key          = "docuseal/codebuild/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

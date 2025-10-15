terraform {
  backend "s3" {
    profile      = "flip"
    bucket       = "goflipai-terraform-state-dev"
    region       = "us-gov-west-1"
    key          = "docuseal/app/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

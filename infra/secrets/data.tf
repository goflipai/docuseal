data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "rds/terraform.tfstate"
  }
}

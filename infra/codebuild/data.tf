data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-dev"
    region  = "us-gov-west-1"
    key     = "networking/terraform.tfstate"
  }
}

data "aws_security_group" "cluster_vpc_access" {
  filter {
    name   = "group-name"
    values = ["dev-cluster-vpc-cluster-access"]
  }
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.networking.outputs.vpc_id]
  }
}

data "terraform_remote_state" "shared_secrets" {
  backend = "s3"
  config = {
    profile = "flip"
    bucket  = "goflipai-terraform-state-shared"
    region  = "us-gov-west-1"
    key     = "secrets/terraform.tfstate"
  }
}

data "aws_secretsmanager_secret_version" "github_runner_personal_access_token" {
  secret_id = data.terraform_remote_state.shared_secrets.outputs.github_runner_personal_access_token_id
}

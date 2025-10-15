provider "aws" {
  region  = local.region
  profile = "flip"
  default_tags {
    tags = {
      Project     = "goflipai"
      ManagedBy   = "terraform"
      Owner       = "devops-team"
      Environment = local.env
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
  registry {
    url      = "oci://${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
  experiments {
    manifest = true
  }
}

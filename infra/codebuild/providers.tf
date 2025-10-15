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

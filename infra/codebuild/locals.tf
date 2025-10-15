locals {
  region          = "us-gov-west-1"
  env             = "shared"
  project_name    = "docuseal"
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.networking.outputs.private_subnet_ids
  subnet_arns     = data.terraform_remote_state.networking.outputs.private_subnet_arns
  github_repo_url = "https://github.com/goflipai/docuseal.git"
  github_pat      = data.aws_secretsmanager_secret_version.github_runner_personal_access_token.secret_string
  # Use the following command to get the list of current docker images:
  # aws codebuild list-curated-environment-images --region us-gov-west-1 --profile flip --query 'platforms[?platform==`UBUNTU`]' --output text
  # environment_image = "aws/codebuild/standard:7.0"
  # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
  # compute_type      = "BUILD_GENERAL1_MEDIUM"
}

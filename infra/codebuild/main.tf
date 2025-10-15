module "github-runner" {
  source = "git@github.com:goflipai/flip-infra.git//modules/codebuild-github-runner"

  name        = "github-runner-${local.project_name}"
  vpc_id      = local.vpc_id
  subnet_ids  = local.subnet_ids
  subnet_arns = local.subnet_arns
  security_group_ids = [
    data.aws_security_group.cluster_vpc_access.id,
  ]
  github_personal_access_token = local.github_pat
  source_location              = local.github_repo_url
}

locals {
  account_id      = data.aws_caller_identity.this.account_id
  partition       = data.aws_partition.this.partition
  region          = "us-gov-west-1"
  env             = "dev"
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
  lb_arn          = data.terraform_remote_state.lbs.outputs.lb_arn
  lb_listener_arn = data.terraform_remote_state.lbs.outputs.listener_arns["https"]
  lb_sec_grp_id   = data.terraform_remote_state.lbs.outputs.security_group_id

  docuseal_domain = "docuseal.${local.env}.goflip.ai"

  repo_url                  = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
  chart                     = "flip-app-chart-${local.env}"
  docuseal_user_secret_name = "${local.env}-flip-docuseal-user"

  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_name
  docuseal_svc_acct_name = "flip-docuseal-sa"

  repo_name = "docuseal"
  image_ids = reverse(
    sort(
      [
        for img in data.aws_ecr_images.this.image_ids
        : img.image_tag if img.image_tag != null
      ]
    )
  )
  latest_image = local.image_ids[0]

  docuseal_priority = 152
}

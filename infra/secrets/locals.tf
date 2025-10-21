locals {
  region              = "us-gov-west-1"
  env                 = "dev"
  db_engine           = data.terraform_remote_state.rds.outputs.instances.postgres.engine
  db_host             = data.terraform_remote_state.rds.outputs.instances.postgres.host
  db_port             = data.terraform_remote_state.rds.outputs.instances.postgres.port
  db_user_secret_name = "${local.env}-docuseal-db-user"
  db_user_name        = "docuseal"
}

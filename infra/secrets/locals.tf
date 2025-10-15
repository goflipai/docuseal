locals {
  region              = "us-gov-west-1"
  env                 = "dev"
  db_engine           = data.terraform_remote_state.rds.outputs.db_engine
  db_host             = data.terraform_remote_state.rds.outputs.db_host
  db_port             = data.terraform_remote_state.rds.outputs.db_port
  db_user_secret_name = "${local.env}-flip-db-user"
  db_user_name        = "api"

  docuseal_db_user_secret_name = "${local.env}-flip-docuseal-user"
}

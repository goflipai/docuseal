resource "random_string" "docuseal_password" {
  length = 16
}

module "docuseal_db_user" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.3"

  # Secret
  name        = local.docuseal_db_user_secret_name
  description = "The db user `docuseal` used by the Docuseal deployment."
  # We don't really need to recover this since we aren't going
  # to be rotating it regularly and the values themselves
  # aren't as important as the values being in sync in the
  # db and the secret
  recovery_window_in_days = 0
  secret_string = jsonencode({
    # Take note of the 2 in the engine below
    # mysql2://username:password@host:port/database_name
    dburl = "${local.db_engine}2://docuseal:${random_string.docuseal_password.result}@${local.db_host}:${local.db_port}/docuseal?schema=public"
  })

  tags = {
    Name = local.docuseal_db_user_secret_name
  }
}

resource "random_string" "docuseal_secret_base_key" {
  length = 128
}

module "docuseal_cipher_key" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.3"

  # Secret
  name        = "${local.env}-flip-docuseal-cipher-key"
  description = "The cipher key used by the Docuseal deployment."
  # We don't really need to recover this since we aren't going
  # to be rotating it regularly and the values themselves
  # aren't as important as the values being in sync in the
  # db and the secret
  recovery_window_in_days = 0
  secret_string           = random_string.docuseal_secret_base_key.result

  tags = {
    Name = "${local.env}-flip-docuseal-cipher-key"
  }
}

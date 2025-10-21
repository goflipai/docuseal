resource "random_string" "docuseal_password" {
  length = 16
}


/*
To create the db user:

- Connect to the database as an admin user:
    psql -h dev-docuseal.c4vaw0ge8gij.us-gov-west-1.rds.amazonaws.com -U docusealmasterdev
- Create the user:
    CREATE USER docuseal WITH PASSWORD 'your_password_here';
- Create the database if it doesn't exist:
    CREATE DATABASE docuseal OWNER docuseal;
- Grant privileges:
    GRANT ALL PRIVILEGES ON DATABASE docuseal TO docuseal;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO docuseal;
*/

module "docuseal_db_user" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.3"

  # Secret
  name        = local.db_user_secret_name
  description = "The db user `docuseal` used by the Docuseal deployment."
  # We don't really need to recover this since we aren't going
  # to be rotating it regularly and the values themselves
  # aren't as important as the values being in sync in the
  # db and the secret
  recovery_window_in_days = 0
  secret_string = jsonencode({
    engine   = local.db_engine,
    host     = local.db_host,
    username = "docuseal",
    password = random_string.docuseal_password.result,
    dbname   = "docuseal",
    port     = local.db_port
    dburl    = "postgresql://docuseal:${random_string.docuseal_password.result}@${local.db_host}:${local.db_port}/docuseal?schema=public"
  })

  tags = {
    Name = local.db_user_secret_name
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

/*
  Steps to deploy a first-time Docuseal instance:
  1. Provision a new ACM certificate for the Docuseal domain (e.g., docuseal.<env>.goflip.ai)
    in the flip-infra repo
  2. Configure the domain in namecheap to point to the ALB created in the networking module
  3. Provision a new secret in AWS Secrets Manager for the Docuseal database user:
    - Name: <env>-flip-docuseal-user
  4. Update the locals file and the manifest for the secret below to use the correct name
  5. Modify the ./values/docuseal.yaml file as necessary and pass the appropriate values to it
    through the templatefile function below
  6. Create a plan of this terraform configuration to confirm the Docuseal application configuration
      is correct and will deploy successfully
  7. Apply the terraform configuration to deploy the Docuseal application
*/


/*
  TODO:
    remove all docuseal related resources from this terraform state
    import them into the new terraform state in the docuseal repo app module

    remove the resources from this file
*/


/*
  imported using the following command
    terraform import kubectl_manifest.docuseal_api_token_secret external-secrets.io/v1beta1//ExternalSecret//dev-docuseal-api-token//apps
*/
resource "kubectl_manifest" "docuseal_db_url_secret" {
  yaml_body = templatefile("${path.module}/manifests/docuseal_db_url_secret.yaml", {
    namespace  = "apps"
    secretName = local.docuseal_user_secret_name
    storeName  = "flip-secretstore"
  })
}

resource "kubectl_manifest" "docuseal_iam_creds_secret" {
  yaml_body = templatefile("${path.module}/manifests/docuseal_iam_creds_secret.yaml", {
    namespace  = "apps"
    secretName = "dev-docuseal-s3-creds"
    storeName  = "flip-secretstore"
  })
}

// terraform import kubectl_manifest.docuseal_api_token_secret external-secrets.io/v1beta1//ExternalSecret//dev-docuseal-api-token//apps
resource "kubectl_manifest" "docuseal_api_token_secret" {
  yaml_body = templatefile("${path.module}/manifests/docuseal_api_token_secret.yaml", {
    namespace  = "apps"
    secretName = "dev-docuseal-api-token"
    storeName  = "flip-secretstore"
  })
}


/*
    module.docuseal.helm_release.this

    terraform import module.docuseal.module.lb_target[0].aws_lb_listener_rule.this \
      arn:aws-us-gov:elasticloadbalancing:us-gov-west-1:358252705848:listener-rule/app/dev-ingress/8bb60c1f8688ec8a/a3971dad368cc017/2b6815fd6328a273
    terraform import module.docuseal.module.lb_target[0].aws_lb_target_group.this \
      arn:aws-us-gov:elasticloadbalancing:us-gov-west-1:358252705848:targetgroup/dev-flip-docuseal/379da98b2f970466
*/

/*
  terraform import module.docuseal.helm_release.this apps/flip-docuseal
*/
module "docuseal" {
  source = "git@github.com:goflipai/flip-infra.git//modules/app"

  env                        = local.env
  vpc_id                     = local.vpc_id
  namespace                  = "apps"
  lb_arn                     = local.lb_arn
  lb_listener_arn            = local.lb_listener_arn
  lb_listener_priority       = local.docuseal_priority
  app_domain                 = local.docuseal_domain
  target_group_name          = "${local.env}-flip-docuseal"
  target_port                = 3000
  health_check_path          = "/up"
  health_check_success_codes = ["302"]
  helm_config = {
    "name"       = "flip-docuseal"
    "repository" = "oci://${local.repo_url}" # This tells where the `helm_release` resource to pull the helm chart from
    "chart"      = local.chart
    "version"    = "0.4.5"
    "timeout"    = 180
    "values" = [
      templatefile("./values/docuseal.yaml", {
        repo_url             = local.repo_url # This tells the k8s deployment object that is created by the helm chart where to pull the container image from
        repo_name            = local.repo_name
        image_tag            = local.latest_image
        secret_base_key_ref  = "${local.env}-flip-docuseal-cipher-key"
        service_account_name = local.docuseal_svc_acct_name
        role_arn             = module.backend_pod_identity.iam_role_arn
        host_name            = local.docuseal_domain
        ingressSecGrpId      = local.lb_sec_grp_id
      })
    ]
  }
}

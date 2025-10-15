module "backend_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  use_name_prefix = false
  name            = "${local.env}-docuseal-pod-identity"
  description     = "Pod Identity for the docuseal applications to read/write to S"

  # Explicit association configuration
  association_defaults = {
    cluster_name = local.cluster_name
    namespace    = "apps"
  }
  associations = {
    docuseal = {
      service_account = local.docuseal_svc_acct_name
    }
  }

  attach_custom_policy = true
  source_policy_documents = [
    data.aws_iam_policy_document.s3_access.json
  ]
}

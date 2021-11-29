resource "vault_transit_secret_backend_key" "vault_operator" {
  backend = "transit"
  name    = local.GITLAB_PROJECT_PATH_UNDERSCORE
}

resource "vault_policy" "vault_operator" {
  name   = "kw/${var.gitlab_project_path}/${var.cluster.name}/ns-system/vault-operator"
  policy = <<EOT
# use transit protocol
path "transit/+/${local.GITLAB_PROJECT_PATH_UNDERSCORE}" {
  capabilities = ["update", "read",]
}
EOT
}

## kubernetes_auth role
resource "vault_kubernetes_auth_backend_role" "vault_operator" {
  backend                          = "kw/${var.gitlab_project_path}/${var.cluster.name}"
  bound_service_account_names      = ["vault-operator*"]
  bound_service_account_namespaces = ["system"]
  role_name                        = "vault-operator"
  token_policies                   = [vault_policy.vault_operator.name]
}

resource "kubernetes_config_map" "vault_operator_transit_key" {
  metadata {
    name      = "vault-operator-transit-key"
    namespace = "system"
  }
  data = {
    // we need to specify complete path, not just the name so we will be able to mount transit on different path without code change
    TRANSIT_KEY_PATH = "transit/+/${local.GITLAB_PROJECT_PATH_UNDERSCORE}"
    TRANSIT_KEY_NAME = local.GITLAB_PROJECT_PATH_UNDERSCORE
  }
}

# Cluster k8s auth
resource "vault_auth_backend" "cluster" {
  path = "kw/${var.gitlab_project_path}/${var.cluster.name}"
  type = "kubernetes"
  tune {
    default_lease_ttl = "1h"
    max_lease_ttl     = "720h"
  }
}

resource "vault_kubernetes_auth_backend_config" "cluster" {
  backend            = vault_auth_backend.cluster.path
  kubernetes_host    = "https://${var.cluster.endpoint}"
  kubernetes_ca_cert = base64decode(var.cluster.master_auth.0.cluster_ca_certificate)
  token_reviewer_jwt = data.kubernetes_secret.token_review.data["token"]
  issuer             = "kubernetes/serviceaccount"
}

data "kubernetes_secret" "token_review" {
  metadata {
    name      = kubernetes_service_account.token_review.default_secret_name
    namespace = "system"
  }
}

resource "kubernetes_service_account" "token_review" {
  metadata {
    name      = "role-tokenreview"
    namespace = "system"
  }
}

resource "kubernetes_cluster_role_binding" "token_review" {
  metadata {
    name = "role-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "role-tokenreview"
    namespace = "system"
  }
}

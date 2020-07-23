# terraform-vault-operator-config

```terraform-hcl
module "vault_operator" {
  source = "kiwicom/operator-config/vault"
  providers = {
    vault = vault.enterprise
  }
  gitlab_project_path = local.GITLAB_PROJECT_PATH
  cluster             = google_container_cluster.cluster
}
```

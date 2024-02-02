module "bw_gitlab_pk_passphrase" {
  source = "github.com/studio-telephus/terraform-bitwarden-get-item-login.git?ref=1.0.0"
  id     = "a2124133-90bc-4483-a54f-b10a00b85cd9"
}

module "bw_platform_gitlab_initial" {
  source = "github.com/studio-telephus/terraform-bitwarden-get-item-login.git?ref=1.0.0"
  id     = "59d269ce-2b94-48b1-8ff0-b10a00db46e5"
}

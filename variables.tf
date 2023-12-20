variable "gitlab_runner_registration_key" {
  type      = string
  sensitive = true
}

variable "git_sa_username" {
  type = string
}

variable "git_sa_token" {
  type      = string
  sensitive = true
}

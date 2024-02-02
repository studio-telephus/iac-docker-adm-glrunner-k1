locals {
  name              = "glrunner-k1"
  docker_image_name = "tel-${var.env}-${local.name}"
  container_name    = "container-${var.env}-${local.name}"
  fqdn              = "gitlab.docker.${var.env}.acme.corp"
  gitlab_address    = "https://${local.fqdn}/gitlab"
}

resource "docker_image" "gitlab_runner" {
  name         = local.docker_image_name
  keep_locally = false
  build {
    context = path.module
    build_args = {
      _GITLAB_ADDRESS                 = local.gitlab_address
      _GITLAB_RUNNER_REGISTRATION_KEY = module.bw_gitlab_runner_registration_key.data.password
    }
  }
}

resource "docker_volume" "gitlab_runner_home" {
  name = "volume-${var.env}-${local.name}-home"
}

resource "docker_container" "gitlab_runner" {
  name     = local.container_name
  image    = docker_image.gitlab_runner.image_id
  restart  = "unless-stopped"
  hostname = local.container_name

  networks_advanced {
    name         = "${var.env}-docker"
    ipv4_address = "10.10.0.130"
  }

  volumes {
    volume_name    = docker_volume.gitlab_runner_home.name
    container_path = "/home/gitlab-runner"
    read_only      = false
  }
}

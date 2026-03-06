terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

module "secure_instance" {
  source = "../../modules/secure_instance"

  do_token              = var.do_token
  instance_name         = var.instance_name
  region                = var.region
  size                  = var.size
  image                 = var.image
  admin_user            = var.admin_user
  ssh_key_name          = var.ssh_key_name
  auto_detect_runner_ip = var.auto_detect_runner_ip
  ssh_source_addresses  = var.ssh_source_addresses
  team_members          = var.team_members
}

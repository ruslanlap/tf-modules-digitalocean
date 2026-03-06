data "http" "runner_ip" {
  count = var.auto_detect_runner_ip ? 1 : 0
  url   = "https://api.ipify.org"

  request_headers = {
    Accept = "text/plain"
  }
}

locals {
  runner_ip                   = var.auto_detect_runner_ip ? trimspace(data.http.runner_ip[0].response_body) : null
  runner_ssh_source_addresses = local.runner_ip != null && local.runner_ip != "" ? ["${local.runner_ip}/32"] : []
  team_ssh_source_addresses = flatten([
    for member in values(var.team_members) : try(member.source_addresses, [])
  ])
  admin_ssh_public_keys = distinct(compact(concat(
    [trimspace(data.digitalocean_ssh_key.bootstrap.public_key)],
    [for key in values(digitalocean_ssh_key.team) : trimspace(key.public_key)],
  )))
  effective_ssh_source_addresses = distinct(concat(
    local.runner_ssh_source_addresses,
    var.ssh_source_addresses,
    local.team_ssh_source_addresses,
  ))
  cloud_init = yamlencode({
    ssh_pwauth      = false
    package_update  = true
    packages = [
      "ufw",
      "fail2ban",
    ]
    users = [
      "default",
      {
        name                = var.admin_user
        groups              = ["sudo"]
        shell               = "/bin/bash"
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = local.admin_ssh_public_keys
      },
    ]
    write_files = [
      {
        path        = "/etc/fail2ban/jail.local"
        permissions = "0644"
        content     = <<-EOF
          [sshd]
          enabled = true
          port = ssh
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 5
          bantime = 3600
          findtime = 600
        EOF
      },
    ]
    runcmd = [
      "install -d -m 700 -o ${var.admin_user} -g ${var.admin_user} /home/${var.admin_user}/.ssh",
      "touch /home/${var.admin_user}/.ssh/authorized_keys",
      "chown ${var.admin_user}:${var.admin_user} /home/${var.admin_user}/.ssh/authorized_keys",
      "chmod 600 /home/${var.admin_user}/.ssh/authorized_keys",
      "sed -i -E 's/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config",
      "grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config || echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config",
      "grep -q '^KbdInteractiveAuthentication no' /etc/ssh/sshd_config || echo 'KbdInteractiveAuthentication no' >> /etc/ssh/sshd_config",
      "systemctl reload ssh",
      "ufw allow OpenSSH",
      "ufw allow 80/tcp",
      "ufw allow 443/tcp",
      "ufw --force enable",
      "systemctl enable fail2ban",
      "systemctl restart fail2ban",
    ]
  })
}

data "digitalocean_ssh_key" "bootstrap" {
  name = var.ssh_key_name
}

resource "digitalocean_ssh_key" "team" {
  for_each = var.team_members

  name       = "${var.instance_name}-${each.key}"
  public_key = each.value.public_key
}

resource "digitalocean_droplet" "this" {
  image  = var.image
  name   = var.instance_name
  region = var.region
  size   = var.size
  ssh_keys = concat(
    [data.digitalocean_ssh_key.bootstrap.fingerprint],
    [for key in digitalocean_ssh_key.team : key.fingerprint],
  )

  user_data = "#cloud-config\n${local.cloud_init}"
}

resource "digitalocean_firewall" "this" {
  name        = "${var.instance_name}-firewall"
  droplet_ids = [digitalocean_droplet.this.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = local.effective_ssh_source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  lifecycle {
    precondition {
      condition     = length(local.effective_ssh_source_addresses) > 0
      error_message = "At least one SSH source address must be available. Enable auto_detect_runner_ip or provide ssh_source_addresses/team_members source_addresses."
    }
  }
}

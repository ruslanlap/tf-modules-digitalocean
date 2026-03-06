# secure_instance

Reusable Terraform module for provisioning a secure DigitalOcean droplet.

Багаторазовий Terraform-модуль для розгортання захищеного дроплету на DigitalOcean.

## What this module does / Що робить цей модуль

This module creates:
- a DigitalOcean SSH key
- a DigitalOcean droplet with a non-root sudo user
- basic security hardening (UFW, fail2ban, SSH config)

Цей модуль створює:
- SSH-ключ у DigitalOcean
- дроплет з не-root sudo користувачем
- базовий hardening безпеки (UFW, fail2ban, конфігурація SSH)

## Security hardening details / Деталі hardening безпеки

| Feature | Description (EN) | Опис (UA) |
|---------|-------------------|-----------|
| UFW | Allows only SSH, HTTP, HTTPS | Дозволяє тільки SSH, HTTP, HTTPS |
| SSH config | `PermitRootLogin prohibit-password` | Заборона входу root по паролю |
| fail2ban | Blocks IP after 5 failed attempts (1h ban) | Блокує IP після 5 спроб (бан 1 год) |
| Updates | Runs `apt-get upgrade` on provision | Оновлює пакети при створенні |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `do_token` | DigitalOcean API token | `string` | — | yes |
| `instance_name` | Name of the droplet | `string` | `"my-secure-instance"` | no |
| `region` | DigitalOcean region | `string` | `"fra1"` | no |
| `size` | Droplet size slug | `string` | `"s-1vcpu-2gb-70gb-intel"` | no |
| `image` | Droplet image slug | `string` | `"ubuntu-24-04-x64"` | no |
| `admin_user` | Non-root sudo user to create | `string` | `"do"` | no |
| `ssh_key_name` | Name for the SSH key in DigitalOcean | `string` | `"my-do-key"` | no |
| `ssh_public_key_path` | Path to the SSH public key | `string` | `"~/.ssh/do.pub"` | no |
| `ssh_private_key_path` | Path to the SSH private key | `string` | `"~/.ssh/do"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `droplet_id` | ID of the created droplet |
| `droplet_name` | Name of the created droplet |
| `droplet_ip` | Public IPv4 address of the droplet |

## Usage / Використання

### From examples/basic (local) / З examples/basic (локально)

```hcl
module "secure_instance" {
  source = "../../modules/secure_instance"

  do_token             = var.do_token
  instance_name        = "app-server-01"
  region               = "fra1"
  size                 = "s-1vcpu-2gb-70gb-intel"
  image                = "ubuntu-24-04-x64"
  admin_user           = "do"
  ssh_key_name         = "app-server-key"
  ssh_public_key_path  = "~/.ssh/do.pub"
  ssh_private_key_path = "~/.ssh/do"
}
```

### From another project (remote) / З іншого проєкту (віддалено)

```hcl
module "secure_instance" {
  source = "github.com/ruslanlap/terraformvps//modules/secure_instance"

  do_token             = var.do_token
  instance_name        = "production-server"
  region               = "ams3"
  size                 = "s-2vcpu-4gb"
  image                = "ubuntu-24-04-x64"
  admin_user           = "deploy"
  ssh_key_name         = "prod-key"
  ssh_public_key_path  = "~/.ssh/do.pub"
  ssh_private_key_path = "~/.ssh/do"
}
```

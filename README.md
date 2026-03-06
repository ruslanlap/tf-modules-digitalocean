# tf-modules-digitalocean

Reusable Terraform module for provisioning a hardened DigitalOcean VPS.

Багаторазовий Terraform-модуль для розгортання захищеного VPS на DigitalOcean.

---

## Structure / Структура

```text
terraformvps/
├── .github/
├── examples/
│   └── basic/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── modules/
│   └── secure_instance/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── .gitignore
├── README.md
└── versions.tf
```

- `modules/secure_instance` — reusable module with the actual infrastructure logic
- `examples/basic` — minimal working example

---

## Prerequisites / Передумови

### EN

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
2. Create a DigitalOcean account
3. Generate a DigitalOcean API token with read/write access
4. Create an SSH key pair
5. Upload the public key to DigitalOcean under a known name

### UA

1. Встановіть [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
2. Створіть акаунт DigitalOcean
3. Згенеруйте API токен DigitalOcean з правами read/write
4. Створіть SSH-ключ
5. Завантажте публічний ключ у DigitalOcean під відомою назвою

### Generate SSH key / Генерація SSH-ключа

```bash
ssh-keygen -t ed25519 -f ~/.ssh/do -C "your-email@example.com"
```

### Upload key to DigitalOcean / Завантаження ключа в DigitalOcean

```bash
doctl compute ssh-key import my-do-key --public-key-file ~/.ssh/do.pub
```

---

## Step-by-step Guide (EN)

### 1. Clone the repository

```bash
git clone https://github.com/ruslanlap/terraformvps.git
cd terraformvps/examples/basic
```

### 2. Create your variables file

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit `terraform.tfvars`

```hcl
do_token              = "dop_v1_abc123..."
instance_name         = "my-secure-instance"
region                = "fra1"
size                  = "s-1vcpu-2gb-70gb-intel"
image                 = "ubuntu-24-04-x64"
admin_user            = "do"
ssh_key_name          = "my-do-key"
auto_detect_runner_ip = true
ssh_source_addresses  = []

team_members = {}
```

If you want extra team access:

```hcl
team_members = {
  "alice" = {
    public_key       = "ssh-ed25519 AAAA..."
    source_addresses = ["203.0.113.10/32"]
  }
}
```

### 4. Initialize and review

```bash
terraform init
terraform plan
```

Expected resources:
- `digitalocean_droplet`
- `digitalocean_firewall`
- optionally `digitalocean_ssh_key.team[*]` if `team_members` is not empty

### 5. Apply

```bash
terraform apply
```

The droplet is bootstrapped by `cloud-init`, so first SSH may take a short while after `apply` completes.

### 6. Wait for cloud-init and connect

```bash
eval "$(terraform output -raw ssh_ready_hint)"
eval "$(terraform output -raw ssh_connect_command)"
```

Or manually:

```bash
ssh -i ~/.ssh/do do@$(terraform output -raw droplet_ip) 'cloud-init status --wait'
ssh -i ~/.ssh/do do@$(terraform output -raw droplet_ip)
```

### 7. Verify hardening

```bash
sudo ufw status verbose
systemctl is-active fail2ban
sudo sshd -T | rg 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication'
```

---

## Покрокова інструкція (UA)

### 1. Клонуйте репозиторій

```bash
git clone https://github.com/ruslanlap/terraformvps.git
cd terraformvps/examples/basic
```

### 2. Створіть файл змінних

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Заповніть `terraform.tfvars`

```hcl
do_token              = "dop_v1_abc123..."
instance_name         = "my-secure-instance"
region                = "fra1"
size                  = "s-1vcpu-2gb-70gb-intel"
image                 = "ubuntu-24-04-x64"
admin_user            = "do"
ssh_key_name          = "my-do-key"
auto_detect_runner_ip = true
ssh_source_addresses  = []

team_members = {}
```

Якщо хочеш дати доступ команді:

```hcl
team_members = {
  "alice" = {
    public_key       = "ssh-ed25519 AAAA..."
    source_addresses = ["203.0.113.10/32"]
  }
}
```

### 4. Ініціалізуйте і перегляньте план

```bash
terraform init
terraform plan
```

Очікувані ресурси:
- `digitalocean_droplet`
- `digitalocean_firewall`
- за потреби `digitalocean_ssh_key.team[*]`, якщо `team_members` не порожній

### 5. Застосуйте конфігурацію

```bash
terraform apply
```

Початковий hardening робиться через `cloud-init`, тому перший SSH може стати доступним із невеликою затримкою після `apply`.

### 6. Дочекайтесь `cloud-init` і підключіться

```bash
eval "$(terraform output -raw ssh_ready_hint)"
eval "$(terraform output -raw ssh_connect_command)"
```

Або вручну:

```bash
ssh -i ~/.ssh/do do@$(terraform output -raw droplet_ip) 'cloud-init status --wait'
ssh -i ~/.ssh/do do@$(terraform output -raw droplet_ip)
```

### 7. Перевірте hardening

```bash
sudo ufw status verbose
systemctl is-active fail2ban
sudo sshd -T | rg 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication'
```

---

## Module Reference / Довідка Модуля

### Resources created / Створювані ресурси

| Resource | EN | UA |
|---|---|---|
| `digitalocean_droplet` | VPS instance | VPS-інстанс |
| `digitalocean_firewall` | DigitalOcean firewall with SSH/HTTP/HTTPS rules | Фаєрвол DigitalOcean з правилами для SSH/HTTP/HTTPS |
| `digitalocean_ssh_key.team` | Optional team SSH keys managed by Terraform | Необов'язкові SSH-ключі команди під керуванням Terraform |

### Hardening includes / Що входить у hardening

- `cloud-init` bootstrap on first boot
- non-root sudo user
- authorized keys for bootstrap key and optional team members
- DigitalOcean firewall for SSH source CIDRs
- UFW allowing only SSH, HTTP, HTTPS
- `fail2ban` for SSH
- SSH password auth disabled
- root password login disabled

### Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `do_token` | DigitalOcean API token | `string` | n/a |
| `instance_name` | Droplet name | `string` | `"my-secure-instance"` |
| `region` | DigitalOcean region | `string` | `"fra1"` |
| `size` | Droplet size slug | `string` | `"s-1vcpu-2gb-70gb-intel"` |
| `image` | Droplet image slug | `string` | `"ubuntu-24-04-x64"` |
| `admin_user` | Non-root sudo user | `string` | `"do"` |
| `ssh_key_name` | Existing bootstrap SSH key name in DigitalOcean | `string` | `"my-do-key"` |
| `auto_detect_runner_ip` | Allow current Terraform runner public IP for SSH | `bool` | `true` |
| `ssh_source_addresses` | Extra SSH CIDR blocks | `list(string)` | `[]` |
| `team_members` | Extra team SSH keys and CIDRs | `map(object)` | `{}` |

### Outputs

| Name | Description |
|---|---|
| `droplet_id` | ID of the created droplet |
| `droplet_name` | Name of the created droplet |
| `droplet_ip` | Public IPv4 of the droplet |
| `firewall_id` | Attached DigitalOcean firewall ID |
| `effective_ssh_source_addresses` | Final SSH CIDRs applied to the firewall |
| `ssh_ready_hint` | Command that waits for `cloud-init` to finish |

### Example usage from another project / Приклад використання з іншого проєкту

```hcl
provider "digitalocean" {
  token = var.do_token
}

module "secure_instance" {
  source = "github.com/ruslanlap/terraformvps//modules/secure_instance"

  do_token              = var.do_token
  instance_name         = "production-server"
  region                = "fra1"
  size                  = "s-1vcpu-2gb-70gb-intel"
  image                 = "ubuntu-24-04-x64"
  admin_user            = "deploy"
  ssh_key_name          = "prod-key"
  auto_detect_runner_ip = true
  ssh_source_addresses  = ["203.0.113.10/32"]
  team_members = {
    "alice" = {
      public_key       = "ssh-ed25519 AAAA..."
      source_addresses = ["198.51.100.20/32"]
    }
  }
}
```

---

## Cleanup / Видалення

```bash
cd examples/basic
terraform destroy
```
Type `yes` when prompted. This will delete the droplet and SSH key from DigitalOcean.

Введіть `yes` коли з'явиться запит. Це видалить дроплет та SSH-ключ з DigitalOcean.
This removes the droplet, firewall, and any Terraform-managed team SSH keys.

Це видалить дроплет, фаєрвол та всі SSH-ключі команди, якими керує Terraform.
>>>>>>> 866c112 (init)

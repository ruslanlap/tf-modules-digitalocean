variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "instance_name" {
  description = "Name of the droplet"
  type        = string
  default     = "my-secure-instance"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "fra1"
}

variable "size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-2gb-70gb-intel"
}

variable "image" {
  description = "Droplet image slug"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "admin_user" {
  description = "Non-root sudo user to create"
  type        = string
  default     = "do"
}

variable "ssh_key_name" {
  description = "Name of an existing bootstrap SSH key in DigitalOcean used by Terraform to connect"
  type        = string
  default     = "my-do-key"
}

variable "auto_detect_runner_ip" {
  description = "Automatically allow the public IP of the machine running Terraform to reach SSH"
  type        = bool
  default     = true
}

variable "ssh_source_addresses" {
  description = "Extra CIDR blocks allowed to reach SSH through the DigitalOcean cloud firewall"
  type        = list(string)
  default     = []
}

variable "team_members" {
  description = "Additional team members whose SSH keys should be managed by Terraform and optional firewall CIDRs"
  type = map(object({
    public_key       = string
    source_addresses = optional(list(string), [])
  }))
  default = {}
}

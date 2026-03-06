output "droplet_id" {
  description = "ID of the created droplet"
  value       = digitalocean_droplet.this.id
}

output "droplet_name" {
  description = "Name of the created droplet"
  value       = digitalocean_droplet.this.name
}

output "droplet_ip" {
  description = "Public IPv4 address of the droplet"
  value       = digitalocean_droplet.this.ipv4_address
}

output "firewall_id" {
  description = "ID of the DigitalOcean firewall attached to the droplet"
  value       = digitalocean_firewall.this.id
}

output "effective_ssh_source_addresses" {
  description = "Final SSH CIDR blocks applied to the DigitalOcean firewall"
  value       = local.effective_ssh_source_addresses
}

output "ssh_ready_hint" {
  description = "Command to wait for cloud-init to finish before relying on first SSH session"
  value       = "ssh -i ~/.ssh/do ${var.admin_user}@${digitalocean_droplet.this.ipv4_address} 'cloud-init status --wait'"
}

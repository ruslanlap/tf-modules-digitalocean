output "droplet_id" {
  description = "ID of the created droplet"
  value       = module.secure_instance.droplet_id
}

output "droplet_name" {
  description = "Name of the created droplet"
  value       = module.secure_instance.droplet_name
}

output "droplet_ip" {
  description = "Public IPv4 address of the droplet"
  value       = module.secure_instance.droplet_ip
}

output "ssh_ready_hint" {
  description = "Command to wait for cloud-init to finish before relying on first SSH session"
  value       = module.secure_instance.ssh_ready_hint
}
output "ssh_connect_command" {
  description = "Command to connect to the droplet via SSH"
  value       = "ssh -i ~/.ssh/do ${var.admin_user}@${module.secure_instance.droplet_ip}"
}

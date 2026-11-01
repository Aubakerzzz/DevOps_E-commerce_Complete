output "instance_id" {
  description = "Azure VM ID."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "instance_public_ip" {
  description = "Public IPv4 address for the Azure VM."
  value       = azurerm_public_ip.pip.ip_address
}

output "instance_public_dns" {
  description = "Public FQDN for the Azure VM."
  value       = azurerm_public_ip.pip.fqdn
}

output "ssh_command" {
  description = "SSH command (replace key path)."
  value       = "ssh -i PATH_TO_YOUR_KEY.pem ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
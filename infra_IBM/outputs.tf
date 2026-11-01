output "instance_id" {
  description = "IBM Cloud VPC instance ID."
  value       = ibm_is_instance.vm.id
}

output "instance_public_ip" {
  description = "Public floating IP address for the instance."
  value       = ibm_is_floating_ip.fip.address
}

output "ssh_command" {
  description = "SSH command (replace key path)."
  value       = "ssh -i PATH_TO_YOUR_KEY root@${ibm_is_floating_ip.fip.address}"
}
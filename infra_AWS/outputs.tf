output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IPv4 address for the EC2 instance."
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name for the EC2 instance."
  value       = aws_instance.app.public_dns
}

output "ssh_command" {
  description = "SSH command (replace key path)."
  value       = "ssh -i PATH_TO_YOUR_KEY.pem ubuntu@${aws_instance.app.public_ip}"
}

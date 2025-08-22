output "web_public_ip" {
  description = "Public IP of the InfraManager EC2"
  value       = aws_instance.app.public_ip
}

output "web_public_dns" {
  description = "Public DNS of the InfraManager EC2"
  value       = aws_instance.app.public_dns
}

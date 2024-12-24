output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

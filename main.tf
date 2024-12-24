# Generate a new SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the public key in AWS as a key pair
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Use the private key for SSH access
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Update with the desired AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name

  # Provisioning Nginx
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Update with the correct username for your AMI
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
    }
  }
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key  # Use the public key from the GitHub secret
}

resource "aws_instance" "web_server" {
  ami           = "ami-0fd05997b4dff7aac"  # Example AMI ID, replace with a valid one
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name  # Reference the created key pair

  tags = {
    Name = "WebServer"
  }

  # Provisioner to execute commands to install Nginx
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Default user for Ubuntu instances
      private_key = var.ssh_private_key  # Use the private key from the GitHub secret
      host        = self.public_ip
    }
  }
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
  description = "The public IP of the web server instance"
}

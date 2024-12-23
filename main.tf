provider "aws" {
  region = "ap-south-1"
}

# Create a security group
resource "aws_security_group" "allow_web" {
  name_prefix = "allow_web"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provision an EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-0fd05997b4dff7aac"  
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_web.name]
  
  tags = {
    Name = "WebServer"
  }

  # Ansible remote-exec provisioner to install Nginx
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Update with the correct username (e.g., ubuntu, ec2-user)
      private_key = file("~/.ssh/id_rsa")  # Update with the path to your private key
      host        = self.public_ip
    }
  }
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

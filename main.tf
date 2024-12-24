provider "aws" {
  region = "ap-south-1"  # Update with your AWS region
}

# Variable declaration (make sure to pass the SSH public key through GitHub Actions secrets)
variable "ssh_public_key" {
  description = "The public SSH key to be used for the EC2 instance"
  type        = string
}

# Check if the key pair exists, and delete it if it does
resource "null_resource" "delete_key_pair" {
  provisioner "local-exec" {
    command = "aws ec2 describe-key-pairs --key-name deployer-key || aws ec2 delete-key-pair --key-name deployer-key"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Create the key pair if it doesn't exist
resource "aws_key_pair" "deployer" {
  depends_on = [null_resource.delete_key_pair]

  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}

# EC2 instance resource
resource "aws_instance" "web_server" {
  ami           = "ami-0fd05997b4dff7aac"  # Replace with your AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name  # Use the created or existing key pair

  tags = {
    Name = "WebServer"
  }

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
      private_key = var.ssh_private_key  # The private key from GitHub secrets
      host        = self.public_ip
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Update to your preferred region
}

# Generate a new SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Delete the existing key pair if it exists
resource "null_resource" "delete_existing_key" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 delete-key-pair --key-name deployer-key || echo "Key not found, skipping deletion"
    EOT
  }
  # Run only once
  triggers = {
    always_run = timestamp()
  }
}

# Save the new key pair in AWS
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh

  depends_on = [null_resource.delete_existing_key]
}

# Create an EC2 instance using the new key
resource "aws_instance" "web_server" {
  ami           = "ami-0fd05997b4dff7aac" # Update with your preferred AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Update according to your AMI's default username
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
    }
  }
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

provider "aws" {
  region = "ap-south-1"  # Update with your AWS region  
}

# Check if the key pair exists, and delete it if it does
resource "null_resource" "delete_key_pair" {
  provisioner "local-exec" {
    command = <<EOT
      # Install AWS CLI (Ubuntu)
      sudo apt-get update
      sudo apt-get install -y awscli

      # Configure AWS CLI (Optional: you can skip if using IAM role on EC2 instances)
      aws configure set aws_access_key_id ${var.aws_access_key_id}
      aws configure set aws_secret_access_key ${var.aws_secret_access_key}
      aws configure set region ${var.aws_region}
      
      # Check if the key pair exists
      key_exists=$(aws ec2 describe-key-pairs --key-name deployer-key --query 'KeyPairs[0].KeyName' --output text)
      
      if [ "$key_exists" == "deployer-key" ]; then
        echo "Key pair exists, deleting..."
        aws ec2 delete-key-pair --key-name deployer-key
        echo "Key pair deleted."
      else
        echo "Key pair does not exist."
      fi
    EOT
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
  ami           = "ami-053b12d3152c0cc71"  # Replace with your AMI ID
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
      private_key = var.ssh_private_key  # Directly use the private key from GitHub secrets
      host        = self.public_ip
      agent       = false
      timeout     = "2m"  # Optional: Add a timeout to ensure SSH connections don't hang indefinitely
    }
  }
}

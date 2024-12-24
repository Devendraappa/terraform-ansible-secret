variable "ssh_public_key" {
  description = "The public SSH key to be used for the EC2 instance"
  type        = string
}

variable "ssh_private_key" {
  description = "The private SSH key for connecting to the EC2 instance"
  type        = string
}

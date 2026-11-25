
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
  default     = "jenkins-ec2-key"
}

variable "my_ip" {
  description = "Your public IP address with /32"
  type        = string
}

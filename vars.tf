variable "AWS_REGION" {
  default = "us-east-1"
}

variable "PRIVATE_KEY_PATH" {
  default = "rsa"
}

variable "PUBLIC_KEY_PATH" {
  default = "rsa.pub"
}

variable "EC2_USER" {
  default = "ubuntu"
}

variable "AMI" {
  default = "ami-0cfc05f17eac80275"
}

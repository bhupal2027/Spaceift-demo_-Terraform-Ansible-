variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
  default     = "ec2"
}

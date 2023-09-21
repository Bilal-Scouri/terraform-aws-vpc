variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  type    = string
  default = "172.18.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "insset-ccm"
}

variable "azs" {
  type    = map(string) 
  default = {"a" = 0, "b" = 1}  
}
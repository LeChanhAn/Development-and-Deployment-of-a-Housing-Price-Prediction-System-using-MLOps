variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project_name" {
  type    = string
  default = "housing-mlops"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
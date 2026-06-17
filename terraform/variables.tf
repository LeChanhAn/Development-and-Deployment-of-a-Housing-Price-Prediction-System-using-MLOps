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

variable "github_repo" {
  description = "The GitHub repository in the format 'owner/repo' that will be allowed to assume the role"
  type        = string
  default     = "khaipd18/MLOps-Housing_Price"
}
variable "cluster_name" {
  type    = string
  default = "housing-mlops-cluster"
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "alb_security_group_id" {
  type        = string
  description = "ID của Security Group gắn trên Load Balancer"
}

variable "api_target_group_arn" {
  type = string
}

variable "ui_target_group_arn" {
  type = string
}

variable "api_image" {
  type = string
}

variable "ui_image" {
  type = string
}

variable "s3_bucket_name" {
  type    = string
  default = "housing-regression-data-mlops"
}

variable "alb_dns_name" {
  description = "Tên miền của Load Balancer để UI gọi API"
  type        = string
}
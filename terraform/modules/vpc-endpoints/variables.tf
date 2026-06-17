variable "region" {
  description = "The AWS region where the VPC endpoint will be created."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the endpoint will be created."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC where the endpoint will be created."
  type        = string
}

variable "private_subnet_list" {
  description = "List of private subnet IDs for the VPC endpoint."
  type        = set(string)
}

variable "route_table_list" {
  description = "List of route table IDs for the VPC endpoint."
  type        = set(string)
}
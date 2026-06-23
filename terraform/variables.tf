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
  default     = "LeChanhAn/Development-and-Deployment-of-a-Housing-Price-Prediction-System-using-MLOps"
}

#ECR configuration
variable "ecr_scan_on_push" {
  description = "Whether to enable image scanning on push"
  type        = bool
  default     = true
}

variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_force_delete" {
  description = "Whether to force delete the repository even if it contains images"
  type        = bool
  default     = true
}

variable "ecr_repository_names" {
  description = "The names of the ECR repositories to create"
  type        = set(string)
  default     = ["housing-api", "housing-ui"]
}


# EKS configuration
# EKS cluster variables
variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "housing-mlops-eks-cluster"
}

variable "eks_vpc_config_override" {
  type = object({
    endpoint_private_access = optional(bool)
    endpoint_public_access  = optional(bool)
    public_access_cidrs     = optional(list(string))
  })
  description = "Override for the default VPC configuration of the EKS cluster. Only include fields that need to be overridden."
  default = {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
}

variable "eks_k8s_version" {
  description = "The Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.35"
}

#eks node group variables
variable "eks_node_group_instance_type" {
  description = "The EC2 instance type to use for the EKS node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_group_ami_type" {
  description = "The AMI type to use for the EKS node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_node_group_capacity_type" {
  description = "The capacity type to use for the EKS node group (e.g., ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_group_disk_size" {
  description = "The disk size (in GiB) to use for the EKS node group."
  type        = number
  default     = 30
}

variable "eks_node_group_scaling_config" {
  description = "The scaling configuration for the EKS node group."
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
  default = {
    desired_size = 3
    max_size     = 4
    min_size     = 2
  }
}

#eks addon variables
variable "eks_cni_version" {
  description = "The version of the VPC CNI plugin to use for the EKS cluster."
  type        = string
  default     = "v1.21.1-eksbuild.7"
}

variable "eks_coredns_version" {
  description = "The version of the CoreDNS addon to use for the EKS cluster."
  type        = string
  default     = "v1.13.2-eksbuild.4"
}

variable "eks_kube_proxy_version" {
  description = "The version of the kube-proxy addon to use for the EKS cluster."
  type        = string
  default     = "v1.35.3-eksbuild.2"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store MLOps Data and Models for Continuous Training."
  type        = string
  default     = "housing-regression-data-mlops"
}
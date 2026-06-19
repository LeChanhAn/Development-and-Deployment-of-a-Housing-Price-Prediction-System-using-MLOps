# This file defines local variables for the EKS cluster configuration, including VPC settings and addon versions.

# The `eks_vpc_configs` local variable contains the default VPC configuration for the EKS cluster, which includes subnet IDs from the VPC module and access settings for the cluster endpoint.
locals {
  eks_vpc_configs = {
    subnet_ids              = module.vpc.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = []
  }

  eks_vpc_conf_finals = merge(
    local.eks_vpc_configs,
    var.eks_vpc_config_override
  )
}
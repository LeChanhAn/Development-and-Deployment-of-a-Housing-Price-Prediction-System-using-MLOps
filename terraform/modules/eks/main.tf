resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.vpc_config.subnet_ids
    endpoint_private_access = var.vpc_config.endpoint_private_access
    endpoint_public_access  = var.vpc_config.endpoint_public_access
    public_access_cidrs     = var.vpc_config.public_access_cidrs
  }
  version                   = var.k8s_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]

}


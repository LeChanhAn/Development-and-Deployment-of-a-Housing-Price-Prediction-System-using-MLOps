resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix = "${var.cluster_name}-node-lt-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
    }
  }
}

#eks node group configuration
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.vpc_config.subnet_ids

  instance_types = var.instance_type
  ami_type       = var.ami_type
  capacity_type  = var.capacity_type

  scaling_config {
    desired_size = var.node_scaling_config.desired_size
    max_size     = var.node_scaling_config.max_size
    min_size     = var.node_scaling_config.min_size
  }

  #launch_template {
  #id      = aws_launch_template.eks_nodes_lt.id
  #version = aws_launch_template.eks_nodes_lt.latest_version
  #}

  launch_template {
    id      = aws_launch_template.eks_nodes_lt.id
    version = aws_launch_template.eks_nodes_lt.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  aws_iam_role_policy_attachment.node_group_AmazonSSMManagedInstanceCore]

}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}
/*resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix = "${var.cluster_name}-nodes-lt"

  instance_type = var.instance_type[0]
  block_device_mappings {
    device_name = "/dev/xvda" # default root device name for Amazon Linux 2 AMIs
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
    }
  }

  vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]
}*/
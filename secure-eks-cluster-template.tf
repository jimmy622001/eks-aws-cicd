resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = false  # Disable public access to EKS API endpoint
    endpoint_private_access = true   # Enable private access from within the VPC
  }

  # Enable encryption for EKS secrets (recommended)
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets_key.arn
    }
    resources = ["secrets"]
  }

  # Enable logging (recommended)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks_logs
  ]

  tags = {
    Name        = local.cluster_name
    Environment = var.environment
  }
}
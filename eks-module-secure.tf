# EKS module implementation with security best practices

provider "aws" {
  region = var.region
}

# KMS Key for EKS Secrets Encryption
resource "aws_kms_key" "eks_secrets_key" {
  description             = "KMS key for EKS cluster secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name        = "${var.cluster_name}-secrets-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "eks_secrets_key_alias" {
  name          = "alias/${var.cluster_name}/secrets-encryption"
  target_key_id = aws_kms_key.eks_secrets_key.key_id
}

# IAM Policy for EKS to use KMS key
resource "aws_iam_policy" "eks_kms_policy" {
  name        = "${var.cluster_name}-kms-policy"
  description = "Policy allowing EKS to use KMS key for secrets encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.eks_secrets_key.arn
      }
    ]
  })
}

# CloudWatch Log Group for EKS Control Plane Logging
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = var.environment
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach KMS policy to EKS Cluster role
resource "aws_iam_role_policy_attachment" "eks_kms_policy_attachment" {
  policy_arn = aws_iam_policy.eks_kms_policy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies for EKS Node Group
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster with Security Best Practices
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = false  # Disable public access to EKS API endpoint
    endpoint_private_access = true   # Enable private access from within the VPC
  }
  
  # Enable encryption for EKS secrets
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets_key.arn
    }
    resources = ["secrets"]
  }
  
  # Enable all EKS control plane logging types
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_kms_policy_attachment,
    aws_cloudwatch_log_group.eks_cluster_logs,
  ]
  
  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${aws_eks_cluster.main.name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids
  
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
  
  instance_types = var.node_instance_types
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read,
  ]
  
  tags = {
    Name        = "${var.cluster_name}-node-group"
    Environment = var.environment
  }
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    Environment = var.environment
  }
}
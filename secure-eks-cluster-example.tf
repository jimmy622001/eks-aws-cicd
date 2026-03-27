resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = false  # Disable public access to EKS API endpoint
    endpoint_private_access = true   # Enable private access from within the VPC
    # Alternative: If public access is required, restrict it to specific IPs
    # endpoint_public_access = true
    # public_access_cidrs   = ["192.168.0.0/24"]  # Replace with your allowed IP range
  }

  # Other configuration...
}
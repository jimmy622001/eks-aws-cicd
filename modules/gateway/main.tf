provider "aws" {
  region = var.region
}

# Create namespace for Gateway API controller
resource "kubernetes_namespace" "gateway_system" {
  metadata {
    name = var.gateway_namespace
  }
}

# Create IAM policy for AWS Gateway API Controller
resource "aws_iam_policy" "gateway_controller_policy" {
  name        = "${var.cluster_name}-AWSGatewayControllerIAMPolicy"
  description = "IAM policy for AWS Gateway API Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTargetGroups",
          "ec2:DescribeTargetHealth",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "cognito-idp:DescribeUserPoolClient"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM Role for Gateway Controller with OIDC
data "aws_iam_policy_document" "gateway_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.gateway_namespace}:aws-gateway-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gateway_controller_role" {
  name               = "${var.cluster_name}-gateway-controller-role"
  assume_role_policy = data.aws_iam_policy_document.gateway_controller_assume_role.json
}

resource "aws_iam_role_policy_attachment" "gateway_controller_attachment" {
  role       = aws_iam_role.gateway_controller_role.name
  policy_arn = aws_iam_policy.gateway_controller_policy.arn
}

# Create service account for Gateway Controller
resource "kubernetes_service_account" "gateway_controller" {
  metadata {
    name      = "aws-gateway-controller"
    namespace = kubernetes_namespace.gateway_system.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.gateway_controller_role.arn
    }
  }
}

# Install Gateway API CRDs
resource "helm_release" "gateway_api_crds" {
  name       = "gateway-api-crds"
  repository = "https://kubernetes-sigs.github.io/gateway-api"
  chart      = "gateway-api-crds"
  namespace  = kubernetes_namespace.gateway_system.metadata[0].name

  depends_on = [kubernetes_namespace.gateway_system]
}

# Install AWS Gateway API Controller
resource "helm_release" "aws_gateway_controller" {
  name       = "aws-gateway-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.gateway_system.metadata[0].name

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.gateway_controller.metadata[0].name
  }

  set {
    name  = "enableGatewayAPI"
    value = "true"
  }

  depends_on = [
    helm_release.gateway_api_crds,
    kubernetes_service_account.gateway_controller
  ]
}

# Create a default GatewayClass
resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "aws-gateway-class"
    }
    spec = {
      controllerName = "gateway.networking.k8s.io/aws-gateway-controller"
    }
  }

  depends_on = [helm_release.aws_gateway_controller]
}

# Create a default Gateway
resource "kubernetes_manifest" "default_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "default-gateway"
      namespace = "default"
    }
    spec = {
      gatewayClassName = "aws-gateway-class"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.gateway_class]
}
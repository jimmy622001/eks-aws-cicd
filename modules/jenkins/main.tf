# Jenkins module implementation

# Use existing providers from parent configuration

# Create Jenkins namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

# Create persistent volume claim for Jenkins
resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# Deploy Jenkins using Helm chart
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  
  values = [<<EOF
controller:
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
  persistentVolume:
    existingClaim: ${kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name}
  JCasC:
    defaultConfig: true

agent:
  enabled: true
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"

rbac:
  create: true

serviceAccount:
  create: true
  name: jenkins

EOF
  ]

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_persistent_volume_claim.jenkins_pvc
  ]
}

# Create cluster autoscaler for Jenkins agents
resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }
}

# Deploy Jenkins agent autoscaler configuration
resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      app = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cluster_autoscaler.metadata[0].name
        
        container {
          name  = "cluster-autoscaler"
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v1.23.0"
          
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--scale-down-utilization-threshold=0.5",
            "--scale-down-unneeded-time=2m",
            "--scale-down-delay-after-add=2m",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}"
          ]
          
          resources {
            limits = {
              cpu    = "100m"
              memory = "300Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "300Mi"
            }
          }
          
          volume_mount {
            name       = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-certificates.crt"
            read_only  = true
          }
        }

        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }
      }
    }
  }
}

# Create a Jenkins controller service specifically for outputs
resource "kubernetes_service" "jenkins_controller" {
  metadata {
    name      = "jenkins-controller"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/component" = "jenkins-controller"
      "app.kubernetes.io/instance"  = "jenkins"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.jenkins]
}

# Create IAM role for Jenkins first
data "aws_iam_policy_document" "jenkins_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.region}.amazonaws.com/id/${split("/", var.eks_oidc_provider_arn)[length(split("/", var.eks_oidc_provider_arn)) - 1]}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.region}.amazonaws.com/id/${split("/", var.eks_oidc_provider_arn)[length(split("/", var.eks_oidc_provider_arn)) - 1]}:sub"
      values   = ["system:serviceaccount:${var.jenkins_namespace}:jenkins-controller-sa"]
    }
  }
}

resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins-eks-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role.json
}

# Create Jenkins service account for use with AWS IAM role
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins-controller-sa"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_role.arn
    }
  }
}

# Output moved to outputs.tf

# Create a Kubernetes service for Jenkins
resource "kubernetes_service" "jenkins_service" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "jenkins"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.jenkins]
}

# Keeping reference to AWS resources but using passed variables instead of direct data sources
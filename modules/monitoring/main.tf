# Monitoring module implementation

# Use existing providers from parent configuration

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.prometheus_namespace
  }
}

# Create Rancher namespace
resource "kubernetes_namespace" "rancher" {
  metadata {
    name = var.rancher_namespace
  }
}

# Deploy Prometheus using Helm chart
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set = [{
    name  = "prometheus.service.type"
    value = "ClusterIP"
  },
  {
    name  = "prometheus.serviceAccount.create"
    value = "true"
  },
  {
    name  = "prometheus.serviceAccount.name"
    value = "prometheus"
  },
  {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  },
  {
    name  = "grafana.persistence.enabled"
    value = "true"
  },
  {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }]

  depends_on = [kubernetes_namespace.monitoring]
}

# Deploy Rancher using Helm chart
resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  namespace  = kubernetes_namespace.rancher.metadata[0].name

  set = [{
    name  = "hostname"
    value = "rancher.${var.cluster_name}.local"
  },
  {
    name  = "replicas"
    value = "1"
  },
  {
    name  = "bootstrapPassword"
    value = "admin"  # This should be changed to a secure password in production
  }]

  depends_on = [kubernetes_namespace.rancher]
}

# Create services for Prometheus and Grafana explicitly for outputs
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector = {
      "app" = "prometheus"
    }
    port {
      port        = 9090
      target_port = 9090
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.prometheus]
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.prometheus]
}

# Outputs moved to outputs.tf

# Create a Kubernetes service for Grafana
resource "kubernetes_service" "grafana_service" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.prometheus]
}

# Keeping reference to AWS resources but using passed variables instead of direct data sources
# Sample configuration for migrating Monitoring services to use Gateway API

# Create a Gateway HTTPRoute resource for Prometheus
resource "kubernetes_manifest" "prometheus_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "prometheus-route"
      namespace = var.prometheus_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = var.gateway_name
          namespace = var.gateway_namespace
          kind      = "Gateway"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/prometheus"
              }
            }
          ]
          backendRefs = [
            {
              name      = "prometheus"
              kind      = "Service"
              namespace = var.prometheus_namespace
              port      = 9090
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_service.prometheus]
}

# Create a Gateway HTTPRoute resource for Grafana
resource "kubernetes_manifest" "grafana_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "grafana-route"
      namespace = var.prometheus_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = var.gateway_name
          namespace = var.gateway_namespace
          kind      = "Gateway"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/grafana"
              }
            }
          ]
          backendRefs = [
            {
              name      = "grafana"
              kind      = "Service"
              namespace = var.prometheus_namespace
              port      = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_service.grafana]
}

# Update the Prometheus service to be ClusterIP instead of LoadBalancer
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.prometheus_namespace
  }
  spec {
    selector = {
      "app" = "prometheus"
    }
    port {
      port        = 9090
      target_port = 9090
    }
    type = "ClusterIP"  # Changed from LoadBalancer to ClusterIP
  }
  depends_on = [helm_release.prometheus]
}

# Update the Grafana service to be ClusterIP instead of LoadBalancer
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.prometheus_namespace
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "ClusterIP"  # Changed from LoadBalancer to ClusterIP
  }
  depends_on = [helm_release.prometheus]
}
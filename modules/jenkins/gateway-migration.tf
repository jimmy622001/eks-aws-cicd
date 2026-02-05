# Sample configuration for migrating Jenkins to use Gateway API

# Create a Gateway HTTPRoute resource for Jenkins
resource "kubernetes_manifest" "jenkins_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "jenkins-route"
      namespace = var.jenkins_namespace
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
                value = "/jenkins"
              }
            }
          ]
          backendRefs = [
            {
              name      = "jenkins-controller"
              kind      = "Service"
              namespace = var.jenkins_namespace
              port      = 8080
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_service.jenkins_controller]
}

# Update the Jenkins service to be ClusterIP instead of LoadBalancer
resource "kubernetes_service" "jenkins_controller" {
  metadata {
    name      = "jenkins-controller"
    namespace = var.jenkins_namespace
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
    type = "ClusterIP"  # Changed from LoadBalancer to ClusterIP
  }
  depends_on = [helm_release.jenkins]
}
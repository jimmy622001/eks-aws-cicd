# Gateway API Migration Guide

This document describes how to migrate from LoadBalancer services to Kubernetes Gateway API in this project.

## What is Gateway API?

Gateway API is a collection of resources that model service networking in Kubernetes. These resources include Gateway, GatewayClass, HTTPRoute, and more. Gateway API is the successor to the Ingress API, providing more features, flexibility, and expressiveness.

## Benefits of Gateway API over LoadBalancers and Ingress

1. **Improved Scalability**: Gateway API provides a more efficient architecture by consolidating multiple ingress points into a single Gateway.
2. **Enhanced Traffic Control**: More sophisticated traffic splitting, routing, and manipulation capabilities.
3. **Better Security**: Improved support for TLS configuration and integration with security policies.
4. **Reduced Costs**: By replacing multiple LoadBalancers with a single Gateway, cloud provider costs can be reduced.
5. **Future-Proof Architecture**: Gateway API is the future standard for Kubernetes service networking.

## Migration Steps

1. Install Gateway API CRDs and controller using the provided `modules/gateway` module:

   ```terraform
   module "gateway" {
     source               = "../modules/gateway"
     region               = var.region
     cluster_name         = module.eks.cluster_name
     eks_oidc_provider_arn = module.eks.oidc_provider_arn
     eks_oidc_provider_url = module.eks.oidc_provider_url
   }
   ```

2. Update services to use ClusterIP instead of LoadBalancer:
   - Sample App: Use the new `app/kubernetes/gateway-deployment.yaml` file
   - Jenkins: Enable the configurations in `modules/jenkins/gateway-migration.tf`
   - Monitoring: Enable the configurations in `modules/monitoring/gateway-migration.tf`

3. Configure routes for each service using HTTPRoute resources as shown in the migration files.

4. Test the Gateway API implementation:
   - Ensure the Gateway is properly created and has an assigned address
   - Verify routes are correctly configured
   - Test access to services through the Gateway

5. Update any DNS records or CloudFront distributions to point to the Gateway address instead of individual LoadBalancer addresses.

## Example Gateway Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default-gateway
  namespace: default
spec:
  gatewayClassName: aws-gateway-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

## Example HTTPRoute Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: sample-app-route
spec:
  parentRefs:
  - name: default-gateway
    kind: Gateway
    namespace: default
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: sample-app-service
      kind: Service
      port: 80
```

## Notes on Using AWS Gateway Controller

- AWS Gateway API Controller (based on AWS Load Balancer Controller) uses an AWS ALB behind the scenes
- Security groups and networking must be correctly configured
- IAM permissions are required as set up in the gateway module
- Annotations can be used for additional customization (see AWS Load Balancer Controller documentation)
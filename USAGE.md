# Detailed Usage Guide for EKS-Jenkins-BitBucket Platform

This document provides comprehensive implementation instructions for the AWS infrastructure with EKS, Jenkins, and BitBucket CI/CD. Follow these steps for successful deployment and operation of the platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Environment-Specific Configurations](#environment-specific-configurations)
4. [HashiCorp Vault Setup](#hashicorp-vault-setup)
5. [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
6. [Deployment Process](#deployment-process)
7. [Monitoring Setup](#monitoring-setup)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- AWS CLI v2 or later
- Terraform v1.0.0 or later
- kubectl v1.20.0 or later
- Docker
- Git
- Access to BitBucket repositories

### Required AWS Resources

1. **IAM User/Role** with these permissions:
   - AmazonEKSClusterPolicy
   - AmazonEKSServicePolicy
   - AmazonVPCFullAccess
   - AmazonS3FullAccess
   - AmazonRoute53FullAccess
   - AmazonEC2FullAccess
   - IAMFullAccess

2. **S3 Buckets** for Terraform state storage:
   ```bash
   aws s3 mb s3://terraform-state-eks-jenkins-bit-dev
   aws s3 mb s3://terraform-state-eks-jenkins-bit-prod
   aws s3 mb s3://terraform-state-eks-jenkins-bit-dr
   ```

3. **AWS CLI Configuration**:
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and preferred region
   ```

## Initial Setup

### 1. Clone the Repository

```bash
git clone <bitbucket-repository-url>
cd EKS_Jenkins_Bit
```

### 2. Configure AWS Regions

The project uses the following default regions:
- Development: `us-west-2`
- Production: `us-west-2`
- Disaster Recovery: `us-east-1`

To modify these default regions, update the following files:
- `environments/dev/terraform.tfvars`
- `environments/prod/terraform.tfvars`
- `environments/dr/terraform.tfvars`

### 3. Domain Name Configuration

The project requires a registered domain for CloudFront and Route53 configurations:

1. Register a domain through AWS Route53 or configure an existing domain
2. Update `domain_name` variable in each environment's `terraform.tfvars` file
3. Ensure the Route53 hosted zone exists for your domain

### 4. SSH Key Pair Creation

```bash
aws ec2 create-key-pair --key-name eks-jenkins-key --query 'KeyMaterial' --output text > eks-jenkins-key.pem
chmod 400 eks-jenkins-key.pem
```

## Environment-Specific Configurations

### Development Environment

1. Navigate to the dev environment directory:
   ```bash
   cd environments/dev
   ```

2. Review and update `terraform.tfvars`:
   ```hcl
   project                     = "eks-jenkins-bit"
   environment                 = "dev"
   region                      = "us-west-2"
   vpc_cidr                    = "10.0.0.0/16"
   public_subnet_cidr          = "10.0.1.0/24"
   private_subnet_cidr         = "10.0.2.0/24"
   db_subnet_cidr              = "10.0.3.0/24"
   availability_zone           = "us-west-2a"
   cluster_version             = "1.23"
   node_instance_types         = ["t3.medium"]
   node_desired_size           = 2
   node_max_size               = 3
   node_min_size               = 1
   domain_name                 = "your-domain.com"
   jenkins_controller_resources = {
     cpu_request    = "500m"
     memory_request = "1Gi"
     cpu_limit      = "1000m"
     memory_limit   = "2Gi"
   }
   ```

3. Initialize and apply Terraform configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

### Production Environment

1. Navigate to the prod environment directory:
   ```bash
   cd environments/prod
   ```

2. Review and update `terraform.tfvars`:
   ```hcl
   project                     = "eks-jenkins-bit"
   environment                 = "prod"
   region                      = "us-west-2"
   vpc_cidr                    = "10.1.0.0/16"
   public_subnet_cidr          = "10.1.1.0/24"
   private_subnet_cidr         = "10.1.2.0/24"
   db_subnet_cidr              = "10.1.3.0/24"
   availability_zone           = "us-west-2a"
   cluster_version             = "1.23"
   node_instance_types         = ["m5.large"]
   node_desired_size           = 3
   node_max_size               = 5
   node_min_size               = 2
   domain_name                 = "your-domain.com"
   ```

3. Initialize and apply Terraform configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

### Disaster Recovery Environment

1. Navigate to the dr environment directory:
   ```bash
   cd environments/dr
   ```

2. Review and update `terraform.tfvars`:
   ```hcl
   project                     = "eks-jenkins-bit"
   environment                 = "dr"
   region                      = "us-east-1"
   vpc_cidr                    = "10.2.0.0/16"
   public_subnet_cidr          = "10.2.1.0/24"
   private_subnet_cidr         = "10.2.2.0/24"
   db_subnet_cidr              = "10.2.3.0/24"
   availability_zone           = "us-east-1a"
   cluster_version             = "1.23"
   node_instance_types         = ["t3.medium"]
   node_desired_size           = 1
   node_max_size               = 3
   node_min_size               = 1
   domain_name                 = "your-domain.com"
   ```

3. Initialize and apply Terraform configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

## HashiCorp Vault Setup

The platform uses HashiCorp Vault for secrets management. Follow these steps to configure Vault:

### 1. Install Vault on the Development EKS Cluster

```bash
# Configure kubectl for dev environment
aws eks update-kubeconfig --name eks-jenkins-bit-dev --region us-west-2

# Create namespace for Vault
kubectl create namespace vault

# Add HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --set server.dev.enabled=false \
  --set server.ha.enabled=true \
  --set server.ha.replicas=3
```

### 2. Initialize Vault

```bash
# Port forward to Vault pod
kubectl port-forward vault-0 8200:8200 -n vault

# In another terminal, initialize Vault
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init -key-shares=5 -key-threshold=3

# IMPORTANT: Safely store the unseal keys and root token
```

### 3. Configure Vault Authentication

```bash
# Log in to Vault using root token
vault login <your-root-token>

# Enable Kubernetes authentication
vault auth enable kubernetes

# Configure Kubernetes authentication
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer="https://kubernetes.default.svc.cluster.local"
```

### 4. Create Vault Policies and Roles

```bash
# Create policy for Jenkins
vault policy write jenkins - <<EOF
path "secret/data/jenkins/*" {
  capabilities = ["read"]
}
EOF

# Create Vault role for Jenkins
vault write auth/kubernetes/role/jenkins \
  bound_service_account_names=jenkins \
  bound_service_account_namespaces=jenkins \
  policies=jenkins \
  ttl=1h
```

### 5. Store Secrets in Vault

```bash
# Enable the KV v2 secrets engine
vault secrets enable -version=2 kv

# Store AWS credentials
vault kv put kv/jenkins/aws \
  access_key=YOUR_ACCESS_KEY \
  secret_key=YOUR_SECRET_KEY

# Store BitBucket credentials
vault kv put kv/jenkins/bitbucket \
  username=YOUR_BITBUCKET_USERNAME \
  password=YOUR_BITBUCKET_PASSWORD

# Store Docker registry credentials
vault kv put kv/jenkins/docker \
  username=YOUR_DOCKER_USERNAME \
  password=YOUR_DOCKER_PASSWORD
```

## Jenkins Pipeline Configuration

### 1. Configure Jenkins Credentials

After Jenkins is deployed, access the Jenkins UI:

1. Get Jenkins URL:
   ```bash
   kubectl get svc -n jenkins
   ```

2. In the Jenkins UI, configure the following credentials:
   - AWS Credentials (ID: `aws-credentials`)
   - AWS Account ID (ID: `aws-account-id`)
   - BitBucket Credentials (ID: `bitbucket-credentials`)
   - Docker Registry Credentials (ID: `docker-registry-credentials`)

### 2. Create Jenkins Pipelines

1. Create the Infrastructure Pipeline:
   - Navigate to Jenkins → New Item → Pipeline
   - Name: `infrastructure-pipeline`
   - Select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `<your-bitbucket-repo-url>`
   - Script Path: `pipelines/infra/Jenkinsfile`

2. Create the EKS Pipeline:
   - Navigate to Jenkins → New Item → Pipeline
   - Name: `eks-pipeline`
   - Select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `<your-bitbucket-repo-url>`
   - Script Path: `pipelines/eks/Jenkinsfile`

3. Create the Application Pipeline:
   - Navigate to Jenkins → New Item → Pipeline
   - Name: `app-pipeline`
   - Select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `<your-bitbucket-repo-url>`
   - Script Path: `pipelines/app/Jenkinsfile`

### 3. Configure BitBucket Webhooks

1. In your BitBucket repository, go to Settings → Webhooks → Add webhook
2. URL: `<jenkins-url>/bitbucket-hook/`
3. Title: Jenkins Integration
4. Select triggers:
   - Repository: Push
   - Pull Request: Created, Updated, Merged

## Deployment Process

### Infrastructure Deployment

Use the Jenkins Infrastructure Pipeline with the following parameters:
- ENVIRONMENT: Select `dev`, `prod`, or `dr`
- ACTION: Select `plan`, `apply`, or `destroy`

### Application Deployment

1. Make changes to the application code in the `app/` directory
2. Commit and push changes to BitBucket repository
3. Based on the branch, the corresponding Jenkins pipeline will be triggered:
   - `development` branch triggers deployment to dev environment
   - `main` branch triggers deployment to prod environment (with manual approval)
   - Manual trigger required for deployment to DR environment

### Manual Deployment (if needed)

```bash
# Configure kubectl for the target environment
aws eks update-kubeconfig --name eks-jenkins-bit-dev --region us-west-2

# Build and push Docker image
cd app
docker build -t <your-repo>/sample-app:latest .
docker push <your-repo>/sample-app:latest

# Deploy to Kubernetes
kubectl apply -f kubernetes/deployment.yaml
```

## Monitoring Setup

### Accessing Monitoring Tools

After deployment, the following monitoring tools are available:

1. **Prometheus**:
   ```bash
   # Get the Prometheus URL
   kubectl get svc -n monitoring prometheus-server
   ```

2. **Grafana**:
   ```bash
   # Get the Grafana URL
   kubectl get svc -n monitoring grafana
   ```
   Default credentials: admin/admin

3. **Rancher**:
   ```bash
   # Get the Rancher URL
   kubectl get svc -n cattle-system rancher
   ```

### Adding Custom Dashboards to Grafana

1. Access the Grafana UI
2. Navigate to Dashboards → Import
3. Import pre-configured dashboards:
   - Kubernetes cluster monitoring (ID: 7249)
   - Jenkins performance and health (ID: 9964)
   - AWS services monitoring (ID: 7617)

### Setting Up Alerts

1. In Grafana, navigate to Alerting → Alert Rules → New alert rule
2. Configure the following recommended alerts:
   - CPU utilization > 80% for 5 minutes
   - Memory utilization > 80% for 5 minutes
   - Container restarts > 5 in 15 minutes
   - Pod pending status > 2 minutes

## Troubleshooting

### Common Issues and Solutions

1. **EKS Cluster Creation Fails**:
   - Check IAM permissions
   - Verify VPC and subnet configurations
   - Check CloudTrail logs for specific errors

   Solution:
   ```bash
   # Check AWS service quotas
   aws service-quotas list-service-quotas --service-code eks
   
   # Verify security groups
   aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<your-vpc-id>"
   ```

2. **Jenkins Cannot Connect to EKS**:
   - Check node role permissions
   - Verify kubeconfig configuration

   Solution:
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --name eks-jenkins-bit-dev --region us-west-2
   
   # Check if Jenkins pods have the correct service account
   kubectl get pods -n jenkins -o yaml | grep serviceAccount
   ```

3. **Application Deployment Fails**:
   - Check Docker image build errors
   - Verify Kubernetes resource quotas

   Solution:
   ```bash
   # Check pod status
   kubectl get pods -n default
   
   # Check pod logs
   kubectl logs <pod-name>
   
   # Check events
   kubectl get events --sort-by='.lastTimestamp'
   ```

4. **DR Failover Not Working**:
   - Check Route53 health check configuration
   - Verify Lambda function permissions

   Solution:
   ```bash
   # Check Route53 health check status
   aws route53 get-health-check --health-check-id <health-check-id>
   
   # Check Lambda logs
   aws logs get-log-events --log-group-name /aws/lambda/eks-failover-handler --log-stream-name <log-stream-name>
   ```

### Support Information

For additional support, contact the platform team:

- Internal Support: platform-support@example.com
- External Support: AWS Support Center

---

*This documentation is maintained by the Infrastructure Team. Please report any issues or suggest improvements to documentation@example.com*
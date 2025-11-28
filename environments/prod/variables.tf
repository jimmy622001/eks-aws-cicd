variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
}

variable "rancher_namespace" {
  description = "Kubernetes namespace for Rancher"
  type        = string
}

variable "rancher_hostname" {
  description = "Hostname for Rancher"
  type        = string
}

variable "prometheus_storage_size" {
  description = "Size of persistent volume for Prometheus"
  type        = string
}

variable "grafana_storage_size" {
  description = "Size of persistent volume for Grafana"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

# DR-related variables
variable "dr_region" {
  description = "AWS region for DR"
  type        = string
}

variable "dr_vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
}

variable "dr_availability_zone" {
  description = "Availability zone for DR subnets"
  type        = string
}

variable "dr_public_subnet_cidr" {
  description = "CIDR block for DR public subnet"
  type        = string
}

variable "dr_private_subnet_cidr" {
  description = "CIDR block for DR private subnet"
  type        = string
}

variable "dr_db_subnet_cidr" {
  description = "CIDR block for DR database subnet"
  type        = string
}

variable "health_check_path" {
  description = "Path for Route53 health check"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval for health checks in seconds"
  type        = number
  default     = 30
}

variable "failover_threshold" {
  description = "Number of consecutive failed health checks to trigger failover"
  type        = number
  default     = 3
}
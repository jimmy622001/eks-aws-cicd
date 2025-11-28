output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "origin_domain_names" {
  description = "Domain names used as origins"
  value       = var.alb_domains
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${var.domain_name}"
}
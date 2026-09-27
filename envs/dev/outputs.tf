output "gcp_workload_identity_provider" {
  description = "Value for workload_identity_provider in the GitHub workflow."
  value       = module.github_oidc_gcp.provider_name
}

output "gcp_service_account_email" {
  description = "Service account the GitHub workflow signs in as."
  value       = module.github_oidc_gcp.service_account_email
}

output "aws_role_arn" {
  description = "Role the GitHub workflow assumes in AWS."
  value       = module.github_oidc_aws.role_arn
}

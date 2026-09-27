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

output "azure_client_id" {
  description = "Client ID the GitHub workflow signs in to Azure with."
  value       = module.github_oidc_azure.client_id
}

output "azure_tenant_id" {
  description = "Entra tenant the identity belongs to."
  value       = data.azurerm_client_config.current.tenant_id
}

# Synthetic public example. Replace IDs in BOTH this file and delivery.azure.json.
global_tags = {
  Owner     = "platform-team@example.com"
  Service   = "network-foundation"
  ManagedBy = "Terraform"
}
company_abbreviation = "example"
primary_region       = "uks"
secondary_region     = "ukw"
subscription_id_map = {
  hub  = "00000000-0000-0000-0000-000000000002"
  pprd = "00000000-0000-0000-0000-000000000003"
  prd  = "00000000-0000-0000-0000-000000000004"
}
diag_log_workspace = null

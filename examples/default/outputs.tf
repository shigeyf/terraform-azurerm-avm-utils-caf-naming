# Example outputs to demonstrate the module's capabilities
output "abbreviations_sample" {
  description = "Sample of CAF-compliant resource type abbreviations"
  value = {
    key_vault       = module.naming.abbreviations["key_vault"]
    storage_account = module.naming.abbreviations["storage_account"]
  }
}

# Example: Building a storage account name using the module outputs
output "example_storage_account_name" {
  description = "Example storage account name using abbreviation and unique hash"
  value       = "${module.naming.abbreviations["storage_account"]}${module.naming.sanitized["project"]}${module.naming.h8}"
}

output "hash_variants" {
  description = "Hash variants of different lengths"
  value = {
    h5  = module.naming.h5
    h8  = module.naming.h8
    h13 = module.naming.h13
  }
}

output "instance" {
  description = "Zero-padded instance number"
  value       = module.naming.instance
}

output "rules_sample" {
  description = "Sample naming rule for key_vault"
  value       = module.naming.rules["key_vault"]
}

output "sanitized" {
  description = "Sanitized input values"
  value       = module.naming.sanitized
}

output "unique_string" {
  description = "13-character deterministic hash (same length as ARM uniqueString)"
  value       = module.naming.unique_string
}

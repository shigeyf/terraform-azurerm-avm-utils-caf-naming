terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# This is a utility module that provides CAF naming data.
# It does not deploy any Azure resources.
module "naming" {
  source = "../../"

  # source  = "Azure/avm-utl-caf-naming/azurerm"
  # version = "~> x.x"

  enable_telemetry = var.enable_telemetry

  # Unique string generation (similar to ARM uniqueString)
  # Use a seed to generate deterministic hash values
  unique_string_seed = ["my-subscription-id", "my-resource-group", "eastus"]

  # Sanitize inputs for use in resource names
  # Output is lowercase alphanumeric only
  sanitize_inputs = {
    project     = "My-Project!"
    environment = "PROD"
    team        = "Platform-Team"
  }

  # Instance numbering for sequential naming
  instance_number  = 1
  instance_padding = 3
}

# Example outputs to demonstrate the module's capabilities
output "abbreviations_sample" {
  description = "Sample of CAF-compliant resource type abbreviations"
  value = {
    key_vault       = module.naming.abbreviations["key_vault"]
    storage_account = module.naming.abbreviations["storage_account"]
  }
}

output "rules_sample" {
  description = "Sample naming rule for key_vault"
  value       = module.naming.rules["key_vault"]
}

output "unique_string" {
  description = "13-character deterministic hash (same length as ARM uniqueString)"
  value       = module.naming.unique_string
}

output "hash_variants" {
  description = "Hash variants of different lengths"
  value = {
    h5  = module.naming.h5
    h8  = module.naming.h8
    h13 = module.naming.h13
  }
}

output "sanitized" {
  description = "Sanitized input values"
  value       = module.naming.sanitized
}

output "instance" {
  description = "Zero-padded instance number"
  value       = module.naming.instance
}

# Example: Building a storage account name using the module outputs
output "example_storage_account_name" {
  description = "Example storage account name using abbreviation and unique hash"
  value       = "${module.naming.abbreviations["storage_account"]}${module.naming.sanitized["project"]}${module.naming.h8}"
}

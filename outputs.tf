# outputs.tf

# Naming data outputs

# Unique string hash outputs

# Sanitization outputs

# Sequential numbering outputs

# Status output (meta information)

output "_status" {
  description = <<DESCRIPTION
Implementation status of each output feature.
Use this to check if a feature is available before using it.

Values:
  - true: Feature is implemented and has data
  - false: Feature is not yet implemented or no input provided
DESCRIPTION
  value = {
    abbreviations  = length(local.abbreviations) > 0
    rules          = length(local.rules) > 0
    resource_types = length(local.resource_types) > 0
    unique_string  = length(var.unique_string_seed) > 0
    sanitized      = length(var.sanitize_inputs) > 0
    instance       = var.instance_number != null
  }
}

output "abbreviations" {
  description = <<DESCRIPTION
CAF-compliant resource type abbreviations.
Map of resource type key to abbreviation string.

Keys use resource names without "azurerm_" prefix for ARM resources.
Data-plane resources use custom naming.

Example:
  {
    key_vault       = "kv"
    storage_account = "st"
    virtual_network = "vnet"
  }
DESCRIPTION
  value       = local.abbreviations
}

output "h10" {
  description = "10-character deterministic hash from unique_string_seed."
  value       = local.h10
}

output "h11" {
  description = "11-character deterministic hash from unique_string_seed."
  value       = local.h11
}

output "h12" {
  description = "12-character deterministic hash from unique_string_seed."
  value       = local.h12
}

output "h13" {
  description = "13-character deterministic hash from unique_string_seed (same length as ARM uniqueString)."
  value       = local.h13
}

output "h3" {
  description = "3-character deterministic hash from unique_string_seed."
  value       = local.h3
}

output "h4" {
  description = "4-character deterministic hash from unique_string_seed."
  value       = local.h4
}

output "h5" {
  description = "5-character deterministic hash from unique_string_seed."
  value       = local.h5
}

output "h6" {
  description = "6-character deterministic hash from unique_string_seed."
  value       = local.h6
}

output "h7" {
  description = "7-character deterministic hash from unique_string_seed."
  value       = local.h7
}

output "h8" {
  description = "8-character deterministic hash from unique_string_seed."
  value       = local.h8
}

output "h9" {
  description = "9-character deterministic hash from unique_string_seed."
  value       = local.h9
}

output "hash_full" {
  description = "Full 64-character SHA256 hash from unique_string_seed. Use substr() for custom lengths."
  value       = local.unique_string_hash
}

output "instance" {
  description = <<DESCRIPTION
Zero-padded instance number for sequential naming.
Generated from instance_number and instance_padding variables.

Example:
  instance_number = 1, instance_padding = 3 → "001"
  instance_number = 42, instance_padding = 4 → "0042"
DESCRIPTION
  value       = local.instance
}

output "resource_types" {
  description = <<DESCRIPTION
Resource key to Azure ARM resource type mapping.
Map of resource key to Azure ARM resource type.
Data-plane resources have null value.

Example:
  {
    key_vault        = "Microsoft.KeyVault/vaults"
    storage_account  = "Microsoft.Storage/storageAccounts"
    key_vault_secret = null  # Data-plane resource
  }
DESCRIPTION
  value       = local.resource_types
}

output "rules" {
  description = <<DESCRIPTION
Resource naming constraints per resource type.
Map of resource type key to rule object containing:
  - arm_type: Azure ARM resource type (e.g., "Microsoft.KeyVault/vaults")
  - abbreviation: CAF abbreviation
  - min_length: Minimum name length
  - max_length: Maximum name length
  - pattern: Regex pattern for valid names
  - scope: Naming scope (one of: global, subscription, resource_group, parent, data)

Scope values:
  - global: Must be unique across all of Azure
  - subscription: Must be unique within a subscription
  - resource_group: Must be unique within a resource group
  - parent: Must be unique within the parent resource
  - data: Data-plane resource (unique within parent)

Example:
  {
    key_vault = {
      arm_type     = "Microsoft.KeyVault/vaults"
      abbreviation = "kv"
      min_length   = 3
      max_length   = 24
      pattern      = "^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$"
      scope        = "global"
    }
    key_vault_secret = {
      arm_type     = null
      abbreviation = "kvsec"
      min_length   = 1
      max_length   = 127
      pattern      = "^[a-zA-Z0-9-]+$"
      scope        = "data"
    }
  }
DESCRIPTION
  value       = local.rules
}

output "sanitized" {
  description = <<DESCRIPTION
Sanitized input values (lowercase alphanumeric only).
Keys match the input keys from sanitize_inputs variable.

Example:
  Input:  { project = "My-Project!", environment = "PROD" }
  Output: { project = "myproject", environment = "prod" }
DESCRIPTION
  value       = local.sanitized
}

output "unique_string" {
  description = <<DESCRIPTION
Deterministic hash string (13 characters) similar to ARM uniqueString.
Generated from unique_string_seed variable using SHA256.
Returns empty string if unique_string_seed is not provided.

Example usage:
  module "naming" {
    source = "Azure/avm-utils-caf-naming/azurerm"
    unique_string_seed = [data.azurerm_resource_group.example.id]
  }

  resource "azurerm_storage_account" "example" {
    name = "st$${module.naming.unique_string}"  # st + 13 chars = 15 chars
  }
DESCRIPTION
  value       = local.h13
}

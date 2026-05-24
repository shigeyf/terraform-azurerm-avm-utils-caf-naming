# locals.tf

# Placeholder locals - to be replaced with actual data from generated files
# Run `make generate` to regenerate these from source data

locals {
  # CAF abbreviations: map of resource key to abbreviation
  # Keys use resource names without "azurerm_" prefix
  # Data source: _locals.abbreviations.tf (generated)
  # Example:
  #   key_vault       = "kv"
  #   storage_account = "st"
  abbreviations = local._abbreviations
  h10           = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 10) : ""
  h11           = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 11) : ""
  h12           = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 12) : ""
  h13           = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 13) : ""
  # Hash length variants (h3 through h13)
  # Use these for short resource name suffixes
  h3 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 3) : ""
  h4 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 4) : ""
  h5 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 5) : ""
  h6 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 6) : ""
  h7 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 7) : ""
  h8 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 8) : ""
  h9 = length(var.unique_string_seed) > 0 ? substr(local.unique_string_hash, 0, 9) : ""
  # Zero-padded instance number for sequential naming
  instance = var.instance_number != null ? format("%0${var.instance_padding}d", var.instance_number) : ""
  # Resource types: map of resource key to Azure ARM type
  # Data-plane resources have null value
  # Data source: _locals.resource_types.tf (generated)
  # Example:
  #   key_vault        = "Microsoft.KeyVault/vaults"
  #   storage_account  = "Microsoft.Storage/storageAccounts"
  #   key_vault_secret = null
  resource_types = local._resource_types
  # Naming rules: map of resource key to rule object
  # Data source: _locals.rules.tf (generated)
  # Example:
  #   key_vault = {
  #     arm_type     = "Microsoft.KeyVault/vaults"
  #     abbreviation = "kv"
  #     min_length   = 3
  #     max_length   = 24
  #     pattern      = "^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$"
  #     scope        = "global"
  #   }
  #   key_vault_secret = {
  #     arm_type     = null  # Data-plane resource
  #     abbreviation = "kvsec"
  #     min_length   = 1
  #     max_length   = 127
  #     pattern      = "^[a-zA-Z0-9-]+$"
  #     scope        = "data"
  #   }
  rules = local._rules
  # Sanitized inputs (lowercase alphanumeric only)
  # First convert to lowercase, then remove non-alphanumeric characters
  sanitized = {
    for k, v in var.sanitize_inputs : k => replace(lower(v), "/[^a-z0-9]/", "")
  }
  unique_string_hash = length(var.unique_string_seed) > 0 ? sha256(local.unique_string_input) : ""
  # Unique string hash generation (similar to ARM uniqueString)
  # Uses SHA256 for deterministic, reproducible hashes
  unique_string_input = join("-", var.unique_string_seed)
  # Valid scope values
  valid_scopes = ["global", "subscription", "resource_group", "parent", "data"]
}

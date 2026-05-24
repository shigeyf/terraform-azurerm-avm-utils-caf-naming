# CAF Naming Utility Module

This module provides Cloud Adoption Framework (CAF) compliant naming data and utilities for Azure resources in Terraform.

## Features

### CAF Resource Abbreviations

Provides a map of Azure resource types to their CAF-compliant abbreviations.

```hcl
module.naming.abbreviations.key_vault       # "kv"
module.naming.abbreviations.storage_account # "st"
module.naming.abbreviations.virtual_network # "vnet"
```

### Naming Rules

Provides naming constraints for each resource type:

- `arm_type` - Azure ARM resource type (e.g., "Microsoft.KeyVault/vaults")
- `abbreviation` - CAF abbreviation
- `min_length` / `max_length` - Name length constraints
- `pattern` - Regex pattern for valid names
- `scope` - Naming scope (global, subscription, resource_group, parent, data)

```hcl
module.naming.rules.key_vault.max_length # 24
module.naming.rules.key_vault.scope      # "global"
```

### Unique String Generation

Generates deterministic hash strings similar to ARM's `uniqueString()` function:

```hcl
module "naming" {
  source             = "Azure/avm-utl-caf-naming/azurerm"
  unique_string_seed = [azurerm_resource_group.example.id]
}

# Use in resource names
resource "azurerm_storage_account" "example" {
  name = "st${module.naming.unique_string}" # st + 13 chars = 15 chars
}
```

Available hash lengths: `h3`, `h4`, `h5`, `h6`, `h7`, `h8`, `h9`, `h10`, `h11`, `h12`, `h13`, `hash_full` (64 chars).

### Input Sanitization

Sanitizes strings for use in resource names (lowercase alphanumeric only):

```hcl
module "naming" {
  source = "Azure/avm-utl-caf-naming/azurerm"
  sanitize_inputs = {
    project     = "My-Project!"
    environment = "PROD"
  }
}

# Output: { project = "myproject", environment = "prod" }
module.naming.sanitized.project
```

### Instance Numbering

Generates zero-padded instance numbers for sequential naming:

```hcl
module "naming" {
  source           = "Azure/avm-utl-caf-naming/azurerm"
  instance_number  = 1
  instance_padding = 3
}

module.naming.instance # "001"
```

## Usage Example

```hcl
module "naming" {
  source  = "Azure/avm-utl-caf-naming/azurerm"
  version = "~> 0.1"

  unique_string_seed = [azurerm_resource_group.example.id]
  instance_number    = 1
  instance_padding   = 3
  sanitize_inputs = {
    project     = var.project_name
    environment = var.environment
  }
}

# Construct a storage account name
locals {
  # st + project + env + unique + instance = stprodxyz001abc123def45001
  storage_name = join("", [
    module.naming.abbreviations.storage_account,  # "st"
    module.naming.sanitized.project,               # sanitized project name
    module.naming.h6,                              # 6-char unique hash
    module.naming.instance                         # "001"
  ])
}

# Validate against naming rules
locals {
  # Check if name meets requirements
  name_valid = (
    length(local.storage_name) >= module.naming.rules.storage_account.min_length &&
    length(local.storage_name) <= module.naming.rules.storage_account.max_length
  )
}
```

## Supported Resources

This module includes naming data for 500+ Azure resource types, including:

- Compute (Virtual Machines, Scale Sets, AKS, etc.)
- Storage (Storage Accounts, Blob Containers, File Shares, etc.)
- Networking (Virtual Networks, Subnets, Load Balancers, etc.)
- Databases (SQL, CosmosDB, PostgreSQL, MySQL, etc.)
- Security (Key Vault, Managed Identities, etc.)
- And many more...

Use `module.naming.abbreviations` to see all available resource types.

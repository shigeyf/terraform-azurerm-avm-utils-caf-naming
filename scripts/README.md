# Scripts

Scripts for generating Terraform locals files.

## Scripts

### generate_tflocals.py

Generates Terraform locals files from JSON template files.

```bash
python3 scripts/generate_tflocals.py [--templates <dir>] [--output <dir>]
```

**Options**:

| Option              | Default                    | Description         |
| ------------------- | -------------------------- | ------------------- |
| `--templates`, `-t` | `data/generated/templates` | Templates directory |
| `--output`, `-o`    | `.` (current)              | Output directory    |

**Examples**:

```bash
# Run with default settings
python3 scripts/generate_tflocals.py

# Specify custom paths
python3 scripts/generate_tflocals.py -t data/generated/templates -o .
```

## Template Format

Reads JSON files from `data/generated/templates/*.json`.

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "azurerm_storage_account",
  "abbreviation": "st",
  "scope": "global",
  "pattern": "^[a-z0-9]+$",
  "minLength": 3,
  "maxLength": 24
}
```

**Fields**:

| Field          | Required | Description                                                |
| -------------- | -------- | ---------------------------------------------------------- |
| `type`         | ✅       | Azure ARM resource type                                    |
| `name`         | ✅       | Terraform resource name (with `azurerm_` prefix)           |
| `abbreviation` | ✅       | CAF-compliant abbreviation                                 |
| `scope`        | -        | Scope (global, subscription, resource_group, parent, data) |
| `pattern`      | -        | Regex pattern for name validation                          |
| `minLength`    | -        | Minimum character length                                   |
| `maxLength`    | -        | Maximum character length                                   |

## Generated Files

| File                        | Content                                             | Local Variable    |
| --------------------------- | --------------------------------------------------- | ----------------- |
| `_locals.abbreviations.tf`  | Resource abbreviation map                           | `_abbreviations`  |
| `_locals.rules.tf`          | Naming constraints (pattern, min/max length, scope) | `_rules`          |
| `_locals.resource_types.tf` | Terraform key → ARM type mapping                    | `_resource_types` |

## Regeneration Steps

```bash
cd /workspaces/terraform-azurerm-avm-utils-caf-naming

# 1. Run script
python3 scripts/generate_tflocals.py

# 2. Format
terraform fmt _locals.*.tf

# 3. Validate
terraform validate
```

## Data Sources

See [DATA_SOURCES.md](DATA_SOURCES.md) for details on template data origins.

## Data Structure

### Naming Rules (from API Specs)

```hcl
local.naming_rules.storage_storageaccounts = {
  provider     = "Microsoft.Storage"
  api_version  = "2026-04-01"
  resource_key = "Microsoft.Storage/storageAccounts"
  pattern      = "^[a-z0-9]+$"
  min_length   = 3
  max_length   = 24
}
```

### Resource Types (from API Specs)

```hcl
local.resource_types.storage_storageaccounts = {
  provider      = "Microsoft.Storage"
  api_version   = "2026-04-01"
  resource_type = "storageAccounts"
  resource_key  = "Microsoft.Storage/storageAccounts"
}
```

### Abbreviations (from Azure Naming Tool)

```hcl
local.abbreviations.storage_storageaccounts = "st"
local.abbreviations.compute_virtualmachines = "vm"
```

## Key Normalization

Resource keys are normalized from API spec paths:

| Original (API Spec)                                                               | Normalized Key                                            |
| --------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `Microsoft.Storage/storageAccounts`                                               | `storage_storageaccounts`                                 |
| `Microsoft.Storage/storageAccounts/{accountName}/blobServices/default/containers` | `storage_storageaccounts_blobservices_default_containers` |

## Intermediate Files

- `scripts/abbreviations.json` - Generated abbreviation mapping (committed to repo)
- `naming_rules.json` - Extracted naming rules (not committed, regenerate as needed)

## Legacy Scripts

The following scripts are from earlier development and may be removed:

- `extract_naming_rules_v2.py` - Replaced by `extract_from_api_specs.py`
- `merge_naming_data.py` - No longer needed (merging handled differently)
- `generate_terraform_hcl.py` - Replaced by `generate_terraform_locals.py`

## Update Schedule

- **azure-rest-api-specs**: Check monthly or when new Azure services are released
- **Azure Naming Tool**: Check quarterly

## Notes

- The extraction prioritizes azure-rest-api-specs for `pattern`, `minLength`, `maxLength` as they are the authoritative source
- Azure Naming Tool is used for abbreviations and supplementary information
- Some patterns may need escaping for Terraform (e.g., `%{` → `%%{`)

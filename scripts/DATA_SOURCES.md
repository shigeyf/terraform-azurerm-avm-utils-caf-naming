# Azure Naming Rules Data Sources

> **Note**: This document is a reference for template data origins.
> Actual templates are stored in `data/generated/templates/*.json`.

## Template Format

Current template format:

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

## Data Sources

### 1. Azure Naming Tool

**Repository**: https://github.com/mspnp/AzureNamingTool

**Provides**:

- `ShortName` → `abbreviation`
- `scope`
- `lengthMin` / `lengthMax`
- `regx` (regex pattern)
- `validText` (human-readable description)

### 2. azure-rest-api-specs

**Repository**: https://github.com/Azure/azure-rest-api-specs

**Provides**:

- `pattern` (API-level regex)
- `minLength` / `maxLength`
- Provider namespace (Microsoft.\*)

## Field Mapping

| Template Field | Primary Source       | Fallback Source   |
| -------------- | -------------------- | ----------------- |
| `type`         | azure-rest-api-specs | -                 |
| `name`         | Terraform provider   | -                 |
| `abbreviation` | Azure Naming Tool    | -                 |
| `scope`        | Azure Naming Tool    | -                 |
| `pattern`      | azure-rest-api-specs | Azure Naming Tool |
| `minLength`    | azure-rest-api-specs | Azure Naming Tool |
| `maxLength`    | azure-rest-api-specs | Azure Naming Tool |

## Adding New Templates

1. Create a JSON file in `data/generated/templates/`
2. Set required fields (`type`, `name`, `abbreviation`)
3. Run `python3 scripts/generate_tflocals.py`
4. Validate with `terraform validate`

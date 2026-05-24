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
  "maxLength": 24,
  "_source": {
    "abbreviation": "mslearn-abbreviations",
    "pattern": "azurecaf-provider",
    "minLength": "azurecaf-provider",
    "maxLength": "azurecaf-provider"
  }
}
```

## Data Sources

### 1. azure-rest-api-specs (Master)

**Repository**: https://github.com/Azure/azure-rest-api-specs

**Local file**: `tmp/sources/specs/*.json`

**Provides**:

- `type` → ARM resource type (e.g., `Microsoft.Storage/storageAccounts`) - **Master definition**
- `pattern` (API-level regex from OpenAPI specs)
- `minLength` / `maxLength`
- Provider namespace (Microsoft.\*)
- Parameter descriptions

**Priority**: **Master source** for ARM resource types. All resource type definitions originate from Azure REST API specifications.

---

### 2. azurecaf-provider

**Repository**: https://github.com/aztfmod/terraform-provider-azurecaf

**Local file**: `tmp/sources/azurecaf-resourceDefinition.json`

**Provides**:

- `name` → Terraform resource name (e.g., `azurerm_resource_group`)
- `validation_regex` → `pattern`
- `min_length` / `max_length`
- `scope`
- `slug` → `abbreviation`
- `official.resource_provider_namespace` → `type`

**Priority**: Primary source for Terraform resource names and validation patterns.

---

### 3. azure-naming-module

**Repository**: https://github.com/Azure/terraform-azurerm-naming

**Local file**: `tmp/sources/resourceDefinition.json`

**Provides**:

- `name` → friendly resource name
- `regex` → validation pattern
- `length.min` / `length.max`
- `scope`
- `slug` → `abbreviation`

**Priority**: Reference for Azure official naming module compatibility.

---

### 4. azure-naming-tool

**Repository**: https://github.com/mspnp/AzureNamingTool

**Local file**: `tmp/sources/resourcetypes.json`

**Provides**:

- `resource` → ARM resource type (e.g., `Network/virtualNetworks`)
- `ShortName` → `abbreviation`
- `scope`
- `lengthMin` / `lengthMax`
- `regx` → validation pattern
- `validText` → human-readable description

**Priority**: Reference for additional metadata and validText descriptions.

---

### 5. mslearn-naming-rules

**URL**: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

**Provides**:

- Official Azure resource naming rules
- `minLength` / `maxLength`
- Allowed characters and patterns
- Scope definitions

**Priority**: Authoritative source for naming constraints.

---

### 6. mslearn-abbreviations

**URL**: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

**Provides**:

- CAF-recommended abbreviations
- ARM resource types
- Official Microsoft guidance

**Priority**: Authoritative source for CAF abbreviations.

---

## Field Mapping

| Template Field | Primary Source        | Fallback Sources                              |
| -------------- | --------------------- | --------------------------------------------- |
| `type`         | azure-rest-api-specs  | -                                             |
| `name`         | azurecaf-provider     | -                                             |
| `abbreviation` | mslearn-abbreviations | azurecaf-provider, azure-naming-tool          |
| `scope`        | azurecaf-provider     | azure-naming-tool                             |
| `pattern`      | azurecaf-provider     | azure-naming-tool, azure-rest-api-specs       |
| `minLength`    | azurecaf-provider     | azure-naming-tool, mslearn-naming-rules       |
| `maxLength`    | azurecaf-provider  | azure-naming-tool, mslearn-naming-rules       |
| `validText`    | azure-naming-tool  | mslearn-naming-rules                          |

## _source Field Values

Use these identifiers in the `_source` field to track data origin:

| Identifier             | Description                                      |
| ---------------------- | ------------------------------------------------ |
| `azure-rest-api-specs` | Azure REST API specifications (Master for `type`) |
| `azurecaf-provider`    | terraform-provider-azurecaf                      |
| `azure-naming-module`  | Azure/terraform-azurerm-naming                   |
| `azure-naming-tool`    | mspnp/AzureNamingTool                            |
| `mslearn-naming-rules` | MS Learn - Resource name rules                   |
| `mslearn-abbreviations`| MS Learn - CAF abbreviations                     |

## Adding New Templates

1. Create a JSON file in `data/generated/templates/`
2. Set required fields (`type`, `name`, `abbreviation`)
3. Add `_source` field to track data origins
4. Run `python3 scripts/generate_tflocals.py`
5. Validate with `terraform validate`

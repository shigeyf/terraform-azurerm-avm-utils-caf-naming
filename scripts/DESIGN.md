# Data Generation Design Document

> **Status**: DRAFT
>
> This document describes the data extraction and merging strategy for Azure naming rules.
> The actual implementation uses pre-merged templates in `data/generated/templates/*.json`.

## 1. Data Sources Overview

### 1.1 Azure Naming Tool (`resourcetypes.json`)

**Source**: https://github.com/mspnp/AzureNamingTool/blob/main/src/repository/resourcetypes.json

**Primary Purpose**: Provides naming conventions and abbreviations for Azure resources

**Key Format**: `{Provider}/{resourceType}` (e.g., `Storage/storageAccounts`)

| Field                          | Description                                   | Coverage |
| ------------------------------ | --------------------------------------------- | -------- |
| `id`                           | Unique identifier                             | 100%     |
| `resource`                     | Resource path (Provider/Type)                 | 100%     |
| `ShortName`                    | **Abbreviation** (e.g., `st`, `vm`)           | **100%** |
| `scope`                        | Uniqueness scope (global, subscription, etc.) | 95.5%    |
| `lengthMin`                    | Minimum name length                           | 92.5%    |
| `lengthMax`                    | Maximum name length                           | 92.5%    |
| `validText`                    | Human-readable valid character description    | 76.3%    |
| `invalidCharacters`            | Characters not allowed                        | 21.9%    |
| `invalidCharactersStart`       | Characters not allowed at start               | 5.4%     |
| `invalidCharactersEnd`         | Characters not allowed at end                 | 12.3%    |
| `invalidCharactersConsecutive` | Characters that can't repeat                  | 2.7%     |
| `regx`                         | Regex pattern for validation                  | 94.6%    |
| `optional`                     | Optional naming components                    | 95.5%    |
| `exclude`                      | Excluded naming components                    | 95.5%    |
| `property`                     | Property reference                            | 10.2%    |
| `staticValues`                 | Static value options                          | 3.3%     |

**Contains**:

- ✅ Abbreviations (ShortName)
- ✅ Length constraints
- ✅ Regex patterns
- ✅ Scope information
- ✅ Human-readable descriptions

**Does NOT contain**:

- ❌ API-level parameter constraints
- ❌ Provider namespace (e.g., `Microsoft.Storage`)

---

### 1.2 azure-rest-api-specs (OpenAPI/Swagger)

**Source**: https://github.com/Azure/azure-rest-api-specs

**Primary Purpose**: Official Azure REST API specifications

**Key Format**: Path-based (e.g., `Microsoft.Storage/storageAccounts/{accountName}`)

**Data extracted from**:

- `paths` → Path parameters with constraints
- `parameters` → Reusable parameter definitions
- `definitions` → Schema definitions with constraints

| Field         | Source                | Description                  |
| ------------- | --------------------- | ---------------------------- |
| `pattern`     | OpenAPI `pattern`     | Regex validation pattern     |
| `minLength`   | OpenAPI `minLength`   | Minimum length               |
| `maxLength`   | OpenAPI `maxLength`   | Maximum length               |
| `description` | OpenAPI `description` | Parameter description        |
| `type`        | OpenAPI `type`        | Data type (usually `string`) |

**Contains**:

- ✅ Precise regex patterns (from actual API validation)
- ✅ Exact length constraints
- ✅ Parameter-level descriptions
- ✅ Provider namespace (Microsoft.\*)

**Does NOT contain**:

- ❌ Abbreviations
- ❌ Scope information
- ❌ Human-readable valid character descriptions

---

## 2. Key Mapping Challenge

The two sources use **different key formats**:

| Source               | Format                            | Example                                           |
| -------------------- | --------------------------------- | ------------------------------------------------- |
| Azure Naming Tool    | `Provider/Type`                   | `Storage/storageAccounts`                         |
| azure-rest-api-specs | `Microsoft.Provider/Type/{param}` | `Microsoft.Storage/storageAccounts/{accountName}` |

### Mapping Strategy

To merge the data, we need to normalize the keys:

```
Azure Naming Tool:     Storage/storageAccounts
                           ↓ normalize
Normalized Key:        storage/storageaccounts
                           ↑ normalize
azure-rest-api-specs:  Microsoft.Storage/storageAccounts/{accountName}
```

**Normalization Rules**:

1. Remove `Microsoft.` prefix
2. Convert to lowercase
3. Remove path parameters (`{...}`)
4. Extract the resource type from the path

---

## 3. Data Quality Comparison

### Storage Account Example

| Property         | Azure Naming Tool               | azure-rest-api-specs                              |
| ---------------- | ------------------------------- | ------------------------------------------------- |
| **Key**          | `Storage/storageAccounts`       | `Microsoft.Storage/storageAccounts/{accountName}` |
| **Abbreviation** | `st`                            | ❌ N/A                                            |
| **Min Length**   | `3`                             | `3`                                               |
| **Max Length**   | `24`                            | `24`                                              |
| **Pattern**      | `^[a-z0-9]+$`                   | `^[a-z0-9]+$`                                     |
| **Scope**        | `global`                        | ❌ N/A                                            |
| **Valid Text**   | "Lowercase letters and numbers" | ❌ N/A                                            |

---

## 4. Recommended Data Pipeline

```
┌─────────────────────────────┐    ┌─────────────────────────────┐
│   Azure Naming Tool         │    │   azure-rest-api-specs      │
│   (resourcetypes.json)      │    │   (OpenAPI specs)           │
└─────────────┬───────────────┘    └─────────────┬───────────────┘
              │                                  │
              ▼                                  ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│   Extract & Normalize       │    │   Extract & Normalize       │
│   - Key: lowercase          │    │   - Key: from paths         │
│   - Fields: abbrev, scope   │    │   - Fields: pattern, len    │
└─────────────┬───────────────┘    └─────────────┬───────────────┘
              │                                  │
              └──────────────┬───────────────────┘
                             ▼
              ┌─────────────────────────────┐
              │        Merge Data           │
              │   (using normalized key)    │
              └─────────────┬───────────────┘
                            ▼
              ┌─────────────────────────────┐
              │   Template JSON Files       │
              │   (data/generated/templates)│
              └─────────────┬───────────────┘
                            ▼
              ┌─────────────────────────────┐
              │   Generate Terraform        │
              │   (_locals.*.tf)            │
              └─────────────────────────────┘
```

---

## 5. Field Mapping Summary

### Final Output Structure

| Output Field   | Primary Source                | Fallback Source          |
| -------------- | ----------------------------- | ------------------------ |
| `abbreviation` | Azure Naming Tool (ShortName) | Manual override          |
| `min_length`   | azure-rest-api-specs          | Azure Naming Tool        |
| `max_length`   | azure-rest-api-specs          | Azure Naming Tool        |
| `pattern`      | azure-rest-api-specs          | Azure Naming Tool (regx) |
| `scope`        | Azure Naming Tool             | N/A                      |

### Data Priority

1. **Abbreviations**: Azure Naming Tool only (not in API specs)
2. **Patterns**: Prefer azure-rest-api-specs (more authoritative)
3. **Length constraints**: Prefer azure-rest-api-specs (more authoritative)
4. **Scope**: Azure Naming Tool only

---

## 6. Challenges and Solutions

### Challenge 1: Key Mismatch

**Problem**: Different key formats between sources

**Solution**: Create a mapping table with normalized keys:

```json
{
  "storage/storageaccounts": {
    "naming_tool_key": "Storage/storageAccounts",
    "api_spec_key": "Microsoft.Storage/storageAccounts",
    "parameter_name": "accountName"
  }
}
```

### Challenge 2: Missing Abbreviations in API Specs

**Problem**: Abbreviations only exist in Azure Naming Tool

**Solution**:

- Primary: Use Azure Naming Tool data
- Secondary: Allow manual overrides in a separate file
- Generate warnings for resources without abbreviations

### Challenge 3: Multiple Entries per Resource

**Problem**: azure-rest-api-specs may have multiple parameters for same resource

**Solution**: Prioritize parameters named `*Name` (e.g., `accountName`, `containerName`)

### Challenge 4: Coverage Gaps

**Problem**: Some resources exist in one source but not the other

**Solution**:

- Use available data from either source
- Mark source in metadata
- Generate report of unmatched resources

---

## 7. Template Key Decisions

### Using Terraform Resource Names

The final implementation uses the Terraform resource name (from `name` field) as the key:

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "azurerm_storage_account",
  "abbreviation": "st"
}
```

**Conversion rule**:

- Template `name` field: `azurerm_storage_account`
- Strip `azurerm_` prefix → `storage_account`
- Use as the Terraform locals key

**Why this approach**:

1. Direct alignment with Terraform provider resource names
2. No ambiguous ARM type to Terraform key conversion needed
3. Consistent and predictable key naming

### Fallback Conversion (for legacy templates)

If `name` field is missing, convert ARM type programmatically:

1. Remove `Microsoft.` prefix
2. Replace `/` with `_`
3. Convert camelCase to snake_case
4. Lowercase everything

Example: `Microsoft.KeyVault/vaults` → `key_vault_vaults`

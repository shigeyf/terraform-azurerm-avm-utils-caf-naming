#!/usr/bin/env python3
"""
Generate Terraform locals from merged naming rules templates.

Reads JSON files from data/generated/templates/ and generates:
  - _locals.abbreviations.tf: CAF-compliant resource type abbreviations
  - _locals.rules.tf: Resource naming constraints (arm_type, abbreviation, min/max length, pattern, scope)
  - _locals.resource_types.tf: Terraform key to Azure resource type mapping

Usage:
    python3 generate_tflocals.py [--templates <dir>] [--output <dir>]

Example:
    python3 generate_tflocals.py --templates data/generated/templates --output .
"""

import argparse
import json
import re
from pathlib import Path
from typing import Optional


# Valid scope values
VALID_SCOPES = ["global", "subscription", "resource_group", "parent", "data"]


def normalize_resource_key(arm_type: str) -> str:
    """
    Convert ARM resource type to Terraform-friendly key using deterministic rules.

    Conversion rules:
        1. Remove Microsoft. prefix
        2. Replace / with _
        3. Convert camelCase to snake_case
        4. Lowercase everything

    Examples:
        Microsoft.Storage/storageAccounts -> storage_storage_accounts
        Microsoft.KeyVault/vaults -> key_vault_vaults
        Microsoft.Network/virtualNetworks -> network_virtual_networks
        Microsoft.KeyVault/vaults/secrets -> key_vault_vaults_secrets
    """
    if not arm_type:
        return ""

    result = arm_type

    # Remove parameter placeholders like {accountName}
    result = re.sub(r"\{[^}]+\}", "", result)

    # Remove consecutive slashes and trailing slashes
    result = re.sub(r"/+", "/", result).rstrip("/")

    # Remove Microsoft. prefix (case-insensitive)
    result = re.sub(r"^[Mm]icrosoft\.", "", result)

    # Replace / with _
    result = result.replace("/", "_")

    # Convert camelCase to snake_case (insert _ before uppercase letters)
    result = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", result)

    # Lowercase everything
    result = result.lower()

    # Remove consecutive underscores
    result = re.sub(r"_+", "_", result)

    # Remove leading/trailing underscores
    result = result.strip("_")

    return result


def normalize_scope(scope: Optional[str]) -> Optional[str]:
    """Normalize scope value to valid scope."""
    if not scope:
        return None

    scope_lower = scope.lower().strip()

    # Direct matches
    if scope_lower in VALID_SCOPES:
        return scope_lower

    # Common variations
    scope_mappings = {
        "resource group": "resource_group",
        "resourcegroup": "resource_group",
        "rg": "resource_group",
        "sub": "subscription",
        "globally unique": "global",
        "dataplane": "data",
        "data-plane": "data",
        "data plane": "data",
    }

    return scope_mappings.get(scope_lower, scope_lower)


def escape_hcl_string(s: Optional[str]) -> str:
    """Escape string for HCL or return null."""
    if s is None:
        return "null"

    # Escape backslashes first
    s = s.replace("\\", "\\\\")

    # Escape quotes
    s = s.replace('"', '\\"')

    # Escape template directives
    s = s.replace("${", "$${")
    s = s.replace("%{", "%%{")

    return f'"{s}"'


def load_templates(templates_dir: Path) -> list:
    """Load all JSON templates from directory."""
    all_entries = []

    for json_file in sorted(templates_dir.glob("*.json")):
        if json_file.name.startswith("_"):
            continue

        try:
            with open(json_file) as f:
                data = json.load(f)

            # Handle both array and object formats
            if isinstance(data, list):
                all_entries.extend(data)
            elif isinstance(data, dict):
                all_entries.append(data)

        except (json.JSONDecodeError, OSError) as e:
            print(f"Warning: Failed to load {json_file}: {e}")
            continue

    return all_entries


def process_entries(entries: list) -> dict:
    """Process entries into a dict keyed by Terraform key."""
    result = {}

    for entry in entries:
        arm_type = entry.get("type")
        if not arm_type:
            continue

        # Use 'name' field from template, strip 'azurerm_' prefix
        # Fall back to normalize_resource_key if 'name' is missing
        name = entry.get("name", "")
        if name.startswith("azurerm_"):
            tf_key = name[8:]  # Remove 'azurerm_' prefix
        elif name:
            tf_key = name
        else:
            tf_key = normalize_resource_key(arm_type)

        if not tf_key:
            continue

        # Skip duplicates (keep first)
        if tf_key in result:
            continue

        result[tf_key] = {
            "arm_type": arm_type,
            "abbreviation": entry.get("abbreviation"),
            "min_length": entry.get("minLength"),
            "max_length": entry.get("maxLength"),
            "pattern": entry.get("pattern"),
            "scope": normalize_scope(entry.get("scope")),
        }

    return result


def generate_abbreviations_tf(data: dict, output_path: Path) -> None:
    """Generate _locals.abbreviations.tf file."""
    lines = [
        "# This file is auto-generated. Do not edit manually.",
        "# Source: data/generated/templates/*.json",
        "# Generated by: scripts/generate_tflocals.py",
        "",
        "locals {",
        "  # CAF-compliant resource type abbreviations (generated)",
        "  # Map of Terraform key to abbreviation string",
        "  # Use local._abbreviations to access this data",
        "  _abbreviations = {",
    ]

    count = 0
    for tf_key in sorted(data.keys()):
        entry = data[tf_key]
        abbr = entry.get("abbreviation")
        if abbr:
            arm_type = entry.get("arm_type", "")
            lines.append(f'    {tf_key} = "{abbr}"  # {arm_type}')
            count += 1

    lines.append("  }")
    lines.append("}")
    lines.append("")

    with open(output_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Written: {output_path} ({count} abbreviations)")


def generate_rules_tf(data: dict, output_path: Path) -> None:
    """Generate _locals.rules.tf file."""
    lines = [
        "# This file is auto-generated. Do not edit manually.",
        "# Source: data/generated/templates/*.json",
        "# Generated by: scripts/generate_tflocals.py",
        "",
        "locals {",
        "  # Resource naming constraints (generated)",
        "  # Map of Terraform key to rule object",
        "  # Use local._rules to access this data",
        "  _rules = {",
    ]

    count = 0
    for tf_key in sorted(data.keys()):
        entry = data[tf_key]

        # Include all entries (even if only abbreviation is available)
        arm_type = entry.get("arm_type")
        abbreviation = entry.get("abbreviation")
        min_length = entry.get("min_length")
        max_length = entry.get("max_length")
        pattern = entry.get("pattern")
        scope = entry.get("scope")

        lines.append(f"    {tf_key} = {{")
        lines.append(f"      arm_type     = {escape_hcl_string(arm_type)}")
        lines.append(f"      abbreviation = {escape_hcl_string(abbreviation)}")

        if min_length is not None:
            lines.append(f"      min_length   = {min_length}")
        else:
            lines.append("      min_length   = null")

        if max_length is not None:
            lines.append(f"      max_length   = {max_length}")
        else:
            lines.append("      max_length   = null")

        lines.append(f"      pattern      = {escape_hcl_string(pattern)}")
        lines.append(f"      scope        = {escape_hcl_string(scope)}")

        lines.append("    }")
        count += 1

    lines.append("  }")
    lines.append("}")
    lines.append("")

    with open(output_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Written: {output_path} ({count} rules)")


def generate_resource_types_tf(data: dict, output_path: Path) -> None:
    """Generate _locals.resource_types.tf file."""
    lines = [
        "# This file is auto-generated. Do not edit manually.",
        "# Source: data/generated/templates/*.json",
        "# Generated by: scripts/generate_tflocals.py",
        "",
        "locals {",
        "  # Terraform key to Azure ARM resource type mapping (generated)",
        "  # Data-plane resources have null value",
        "  # Use local._resource_types to access this data",
        "  _resource_types = {",
    ]

    count = 0
    for tf_key in sorted(data.keys()):
        entry = data[tf_key]
        arm_type = entry.get("arm_type")

        # Check if this is a data-plane resource (no ARM type or scope is "data")
        if entry.get("scope") == "data" or not arm_type:
            lines.append(f"    {tf_key} = null")
        else:
            lines.append(f'    {tf_key} = "{arm_type}"')
        count += 1

    lines.append("  }")
    lines.append("}")
    lines.append("")

    with open(output_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Written: {output_path} ({count} resource types)")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Terraform locals from merged naming rules templates"
    )
    parser.add_argument(
        "--templates", "-t",
        type=Path,
        default=Path("data/generated/templates"),
        help="Templates directory (default: data/generated/templates)"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("."),
        help="Output directory (default: current directory)"
    )
    args = parser.parse_args()

    # Validate templates directory
    if not args.templates.exists():
        print(f"Error: Templates directory not found: {args.templates}")
        return 1

    # Load templates
    print(f"Loading templates from: {args.templates}")
    entries = load_templates(args.templates)
    print(f"  Loaded {len(entries)} entries")

    if not entries:
        print("Error: No entries found in templates")
        return 1

    # Process entries
    data = process_entries(entries)
    print(f"  Processed {len(data)} unique entries")

    # Stats
    with_abbr = sum(1 for e in data.values() if e.get("abbreviation"))
    with_pattern = sum(1 for e in data.values() if e.get("pattern"))
    with_scope = sum(1 for e in data.values() if e.get("scope"))
    print(f"  With abbreviation: {with_abbr}")
    print(f"  With pattern: {with_pattern}")
    print(f"  With scope: {with_scope}")

    # Generate outputs
    args.output.mkdir(parents=True, exist_ok=True)

    generate_abbreviations_tf(data, args.output / "_locals.abbreviations.tf")
    generate_rules_tf(data, args.output / "_locals.rules.tf")
    generate_resource_types_tf(data, args.output / "_locals.resource_types.tf")

    print(f"\nGeneration complete: {len(data)} entries")
    return 0


if __name__ == "__main__":
    exit(main())

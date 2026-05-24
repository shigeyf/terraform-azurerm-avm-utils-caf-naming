# Examples

This directory contains examples demonstrating how to use the CAF Naming utility module.

## Available Examples

| Example | Description |
|---------|-------------|
| [default](./default/) | Basic usage demonstrating all module features: abbreviations, unique strings, input sanitization, and instance numbering |

## Running Examples

Since this is a utility module that provides naming data only (no Azure resources deployed), you can run the examples locally:

```bash
cd examples/default
terraform init
terraform plan
terraform apply
```

The outputs will show the generated naming data and example resource names.

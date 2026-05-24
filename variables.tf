# variables.tf

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "instance_number" {
  type        = number
  default     = null
  description = <<DESCRIPTION
Instance number for sequential naming (e.g., 1, 2, 3).
Used to generate zero-padded instance strings.

Example:
  instance_number  = 1
  instance_padding = 3

Output:
  instance = "001"
DESCRIPTION
}

variable "instance_padding" {
  type        = number
  default     = 3
  description = <<DESCRIPTION
Number of digits for zero-padded instance number (default: 3).
Used with instance_number to generate padded strings.

Examples:
  instance_padding = 2 → "01", "02", "99"
  instance_padding = 3 → "001", "002", "999"
  instance_padding = 4 → "0001", "0042", "9999"
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.instance_padding >= 1 && var.instance_padding <= 10
    error_message = "instance_padding must be between 1 and 10."
  }
}

variable "sanitize_inputs" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Key-value pairs to sanitize for use in resource names.
Output values are lowercase alphanumeric only (all other characters removed).

Example:
  sanitize_inputs = {
    project     = "My-Project!"
    environment = "PROD"
    team        = "Platform-Team"
  }

Output:
  sanitized = {
    project     = "myproject"
    environment = "prod"
    team        = "platformteam"
  }
DESCRIPTION
  nullable    = false
}

variable "unique_string_seed" {
  type        = list(string)
  default     = []
  description = <<DESCRIPTION
Seed values for deterministic hash generation (similar to ARM uniqueString).
Multiple values are concatenated with '-' delimiter, matching ARM behavior.

Examples:
  - [data.azurerm_resource_group.example.id]
  - [var.subscription_id, var.resource_group_name]
  - [var.project, var.environment, var.location]

Note: This uses SHA256 instead of ARM's SHA1-based algorithm, so the output
will not match ARM uniqueString but will be deterministic and reproducible.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for s in var.unique_string_seed : length(s) > 0])
    error_message = "Seed values must not be empty strings."
  }
}

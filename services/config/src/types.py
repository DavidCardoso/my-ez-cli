"""Type aliases for the config service."""

# A dotted key like "ai.claude.model"
DottedKey = str

# Scalar YAML value (always a string for CLI use)
YamlValue = str

# Optional string result from a get operation
OptionalValue = str | None

# A YAML list value (list of strings)
YamlList = list[str]

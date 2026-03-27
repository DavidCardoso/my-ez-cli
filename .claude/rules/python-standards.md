# Python Standards (Critical Rules)

## Type Hints (Required)

All functions, methods, and variables MUST have explicit type hints.

```python
def complete(self, prompt: str, context: Optional[str] = None) -> str:
    messages: list[dict[str, str]] = [{"role": "user", "content": prompt}]
    return response.content[0].text
```

## Error Handling Pattern

**Always**: Log → Custom Exception → Chain

```python
try:
    response = self.client.messages.create(**request_params)
except AuthenticationError as e:
    self.logger.error(f"Authentication failed: {e}", exc_info=True)
    raise ProviderAuthenticationError(
        provider="anthropic",
        original_error=e
    ) from e
```

**Rules**:
- Always log before raising with `exc_info=True`
- Use custom exceptions from `src/exceptions.py`
- Chain exceptions with `from e`
- NEVER use ValueError/RuntimeError directly

## Logging Levels

**Principle**: Minimize noise. Success is silent.

- `logger.error()` - Fatal errors, auth failures, missing config
- `logger.warning()` - Issues needing attention (unbound ports, fallbacks)
- `logger.debug()` - Everything else (most logs should be debug!)

```python
# Success = debug
logger.debug("All detected ports are already bound")

# Issues = warning
logger.warning("AI response invalid, using fallback suggestions")

# Fatal = error (before raising)
logger.error(f"Authentication failed: {e}", exc_info=True)
```

## AI Model References

**Use tier terminology, NEVER specific model names**

**Tiers**:
- `faster` - Quick tasks (port detection, pattern matching)
- `smarter` - Moderate complexity (error analysis, env suggestions)
- `advanced` - Complex analysis (architecture, code review)

❌ Don't reference: Haiku, Sonnet, Opus, GPT-4 in code/docs
✅ OK in: Provider classes, config files

## Docstrings (Required)

Google-style docstrings on all modules/classes/methods.

```python
def complete(self, prompt: str, context: Optional[str] = None) -> str:
    """
    Generate completion from prompt.

    Args:
        prompt: User prompt
        context: Optional system context

    Returns:
        Generated text response

    Raises:
        ProviderAuthenticationError: If API key invalid
        ProviderAPIError: If API call fails
    """
```

## Code Style

- **Line length**: 100 chars max
- **Naming**: snake_case (vars/functions), PascalCase (classes), UPPER_CASE (constants)
- **Imports**: Standard lib → Third-party → Local

## Testing

- Unit tests for all code
- Mock external dependencies
- 80% coverage minimum
- Descriptive test names grouped by functionality

## Before Submitting

- [ ] Type hints on all functions/variables
- [ ] Error handling follows pattern
- [ ] Custom exceptions used
- [ ] Docstrings present
- [ ] Tests cover all paths
- [ ] `make check` passes

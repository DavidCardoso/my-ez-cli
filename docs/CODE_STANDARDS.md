# Code Standards for My Ez CLI

**Applies to:** All code (Python, Shell)

## Tools & Setup (Python/AI Service)

### Tools
- **Poetry** - Dependency management
- **Ruff** - Linter and formatter
- **Mypy** - Type checker (strict mode)
- **Pre-commit** - Git hooks

### Commands
```bash
# Setup
make install-dev

# Check all
make check

# Auto-fix
make format && make lint-fix

# Add dependencies
poetry add package-name              # production
poetry add --group dev package-name  # development
```

### Configuration
- `pyproject.toml` - Poetry deps, Ruff rules, Mypy settings, Pytest config
- `.pre-commit-config.yaml` - Git hooks
- `poetry.lock` - Locked versions (commit to git)

---

## Type Standards

### Type Hints Required
All functions, methods, and variables must have explicit type hints.

```python
def complete(self, prompt: str, context: Optional[str] = None) -> str:
    messages: list[dict[str, str]] = [{"role": "user", "content": prompt}]
    response: Message = self.client.messages.create(**request_params)
    return response.content[0].text
```

### Custom Types (`src/types.py`)

When same type pattern appears 3+ times, create shared type.

**Defined:**
- `Suggestion` - TypedDict with `description` and `command` fields
- `SuggestionList` - Type alias for `list[Suggestion]`

**Usage:**
```python
from src.types import SuggestionList

def generate_suggestions() -> SuggestionList:
    return [{"description": "Fix issue", "command": "fix-cmd"}]
```

**When to create:**
- Repeated 3+ times across files
- Represents domain concept
- More than 2 fields or nested structure

---

## Error Handling

### Pattern: Log → Custom Exception → Chain

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

### Rules
- Always log before raising with `exc_info=True`
- Use custom exceptions from `src/exceptions.py`
- Chain exceptions with `from e`
- Re-raise validation errors without wrapping

---

## Logging Patterns

### Principle: Minimize Noise

Users don't need to see internal operations. Success is silent.

**Levels:**
- `logger.error()` - Fatal errors, auth failures, missing config
- `logger.warning()` - Issues needing attention (unbound ports, fallbacks)
- `logger.debug()` - Everything else (initialization, operations, success)

**Most logs should be debug, not info!**

```python
# Success = debug
logger.debug("All detected ports are already bound")
logger.debug(f"Anthropic provider initialized with model: {self.model}")

# Issues = warning
logger.warning("AI response invalid, using fallback suggestions")

# Fatal = error (before raising)
logger.error(f"Authentication failed: {e}", exc_info=True)
raise ProviderAuthenticationError(provider="anthropic") from e
```

---

## AI Model References

### Rule: Use tier terminology, never specific model names

**Tiers:**
- **`faster`** - Quick tasks (port detection, pattern matching)
- **`smarter`** - Moderate complexity (error analysis, env suggestions)
- **`advanced`** - Complex analysis (architecture, code review)

```python
class PortDetectorAnalyzer(Analyzer):
    """
    Port binding issue detector.

    Model Tier: Faster (quick pattern matching)
    """
```

**❌ Don't reference:** Haiku, Sonnet, Opus, GPT-4, etc. in code/docs

**✅ OK in:** Provider classes, config files

See [`AI_INTEGRATION.md`](./AI_INTEGRATION.md) for details.

---

## Documentation

### Docstrings Required

Use Google-style docstrings:

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

**Sections:** Summary, Args, Returns, Raises

### Inline Comments

Use sparingly - explain "why", not "what". Code should be self-documenting.

```python
# ✅ Good - explains non-obvious decision
# Claude uses system parameter separately (not in messages array)
if role == 'system':
    system_message = content

# ❌ Bad - restates obvious code
# Try to parse as JSON
parsed = json.loads(ai_response)
```

---

## Testing

### Required
- Unit tests for all code
- Mock external dependencies
- Descriptive test names
- Group by functionality

```python
class TestAnthropicProviderInit:
    """Tests for AnthropicProvider initialization."""

    def test_init_with_api_key_from_config(self):
        """Test initialization with API key from config."""
```

### Custom Exceptions
```python
with pytest.raises(MissingAPIKeyError) as exc_info:
    AnthropicProvider(config, logger)

assert exc_info.value.provider == "anthropic"
```

---

## Code Style

### Basics
- **Line length:** 100 chars max
- **Naming:** snake_case (vars/functions), PascalCase (classes), UPPER_CASE (constants)
- **Imports:** Standard lib → Third-party → Local

```python
# Standard library
import os
from typing import Optional

# Third-party
from anthropic import Anthropic

# Local
from .base import AIProvider
from ..exceptions import ProviderError
```

---

## Checklist

Before submitting:
- [ ] Type hints on all functions/variables
- [ ] Error handling follows log → exception → chain pattern
- [ ] Custom exceptions used (never ValueError/RuntimeError)
- [ ] Docstrings on modules/classes/methods
- [ ] Tests cover all paths with mocks
- [ ] Code follows PEP 8, 100-char limit
- [ ] `make check` passes

---

## Questions?

This is a living document. Open issues or discuss in team meetings for changes.

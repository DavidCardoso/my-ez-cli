---
name: Always write automated tests for new features and fixes
description: Every new feature, behavior, and key business rule or fix must have accompanying automated tests (at minimum unit tests)
type: feedback
---

Always add automated tests alongside new features, behaviors, edge cases, and fixes for key business rules. At minimum, unit tests are required.

**Why:** Tests were missing for `mec purge` when the subcommand was first shipped and needed to be added in a follow-up commit after the user pointed it out. Tests should ship with the feature, not after.

**How to apply:** When implementing any new `mec` subcommand, CLI flag, service endpoint, or business logic fix — write the tests in the same commit (or as part of the same branch). Cover: happy path, edge cases, input validation, and any key business rules (e.g. `--dry-run` must not delete, `--tool` must reject path traversal). Also wire the new test file into `.github/workflows/test.yml`: add to the `unit-tests` matrix and add a smoke test step for the new subcommand's `help` output.

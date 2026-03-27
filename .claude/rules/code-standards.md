# Code Standards (Shared)

## Always write automated tests

Every new feature, behavior, edge case, and key fix must ship with automated tests — not as a follow-up.

**Minimum**: unit tests. Add integration tests when the feature touches Docker, network, or subprocess execution.

**Why:** Tests for `mec purge` were missing when first shipped and had to be added in a follow-up. Tests belong in the same commit as the feature.

**How to apply:**
- New `mec` subcommand or CLI flag → unit tests + smoke test in CI
- New service endpoint → unit tests covering happy path, edge cases, input validation
- Key business rules (e.g. `--dry-run` must not delete, `--tool` must reject path traversal) → dedicated test cases
- Wire new test files into `.github/workflows/test.yml`: add to `unit-tests` matrix and add a smoke test step for the new subcommand's `help` output

## Always run tests locally before committing

Run the relevant test suite (or manual validation) before any `git commit`.

**Why:** Multiple bugs were caught only after committing — running locally first prevents regressions from landing in git history.

**How to apply:**
- Shell script changes: run the affected subcommand manually (e.g. `./bin/mec ai last`, `./bin/mec ai logs`)
- Python service changes: run `pytest` inside the Docker container
- Docker pipeline changes: run the pipeline synchronously first

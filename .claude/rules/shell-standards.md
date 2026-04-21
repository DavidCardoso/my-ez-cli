# Shell Standards

## Smoke test mec CLI changes before committing

After implementing or modifying any `mec` subcommand or shell behavior, always run a manual smoke test before committing.

**Why:** Unit tests may pass while the actual CLI invocation fails due to sourcing, dispatch, or integration issues that only surface at runtime.

**How to apply:**
1. Run the command directly: `./bin/mec <subcommand>`
2. Test help: `./bin/mec <subcommand> help` and `./bin/mec <subcommand> --help`
3. Test edge cases: unknown subcommand, empty input, scriptability (`&& echo "ok" || echo "fail"`)
4. Only then commit.

## Never call python3 directly in host-side scripts

Never call `python3` directly in host-side shell scripts (`common.sh`, `setup.sh`, `bin/*`). Use the `mec-python` wrapper instead.

**Why:** `python3` creates an external host dependency. My Ez CLI aims to be as self-contained as possible. Existing `python3` calls in the codebase are a pre-existing gap, not a justification to add more.

**How to apply:**
- New inline Python logic on the host → use `mec-python -c "..."` or `mec python -c "..."`
- When reviewing or touching existing `python3` calls in shell scripts → flag them for replacement
- Python inside Docker containers (e.g. `ai-service`) is fine — that's the container's own runtime

## Script pattern

All `bin/` wrapper scripts must follow the established pattern:

1. Source `common.sh` using the symlink-safe `SCRIPT_DIR` resolution
2. Call `check_docker` early
3. Use `get_container_name` / `get_container_labels` for naming
4. Use `check_custom_image` for any custom Docker image (local → pull → build fallback)
5. Use `exec_with_ai` to run the final docker command (not bare `docker run`)
6. Use `--rm` for automatic container cleanup

See `CLAUDE.md` for full pattern details.

---
name: add-mec-tool
description: Use when adding a new wrapped tool, converting an existing tool to use a custom Docker image, adding a version variant (e.g. node26), or any other change that introduces a new bin/ script or docker/ image to the mec project. For complex refactors or architecture changes, the skill defers to planning mode instead of implementing directly.
---

# Add mec Tool

## Overview

Guides adding a new tool wrapper or custom Docker image to the mec project. Covers three scenarios in order of complexity. Always announce which scenario applies at the start.

**Announce at start:** "Running add-mec-tool: [scenario]."

---

## Step 1 — Identify the scenario

```
Is this a complex refactor, architecture change, or multi-tool epic?
  YES → Scenario D (defer to planning)

Does the tool need a custom Docker image (not a public one)?
  YES → Scenario B (custom image)

Is this a version variant of an existing tool (e.g. node26 alongside node24)?
  YES → Scenario C (version variant)

Otherwise → Scenario A (new tool, public Docker image)
```

---

## Scenario A — New tool (public Docker image)

A brand new tool that uses an existing public Docker image (e.g. `hashicorp/terraform:latest`, `python:3.14-alpine`).

### Checklist

- [ ] **`bin/<toolname>`** — create following the established pattern:
  1. Source `common.sh` using the symlink-safe `SCRIPT_DIR` resolution
  2. Call `check_docker` early
  3. Set `IMAGE` to the public image (overridable via env var)
  4. Use `get_container_name` / `get_container_labels` for naming
  5. Use `exec_with_ai` to run the final docker command
  6. Use `--rm` for automatic container cleanup
  7. Use `setup_logging "<toolname>" "$IMAGE" "<toolname> ${*}"` before the docker run

- [ ] **`setup.sh`** — add `install_<toolname>()` and `uninstall_<toolname>()`:
  - `install_<toolname>()`: call `check_custom_image` if custom, create symlink in `/usr/local/bin/`, call `track_install "<toolname>"`; handle conflict detection if the tool name clashes with a native binary
  - `uninstall_<toolname>()`: remove symlink (and `mec-<toolname>` alias if applicable), call `track_uninstall "<toolname>"`

- [ ] **`bin/mec`** — add the tool name to the tool dispatch case block (search for `# Tool wrappers`)

- [ ] **`README.md`** — add tool to the tools table with a one-line description and usage example

- [ ] **`CLAUDE.md`** — no change needed for simple tools (docker/ listing only covers custom images)

- [ ] **Tests** — add `tests/unit/test-<toolname>.bats` with at minimum:
  - Script exists and is executable
  - Script sources `common.sh` correctly
  - Help/version command works (smoke test)

- [ ] **CI** — add the test suite to the `unit-tests` matrix in `.github/workflows/test.yml`

---

## Scenario B — Custom Docker image

The tool requires a custom Dockerfile. All of Scenario A, plus:

- [ ] **`docker/<toolname>/Dockerfile`** — with `com.my-ez-cli.*` labels (copy label block from `docker/playwright/Dockerfile`)

- [ ] **`docker/<toolname>/build`** — build script (copy from `docker/playwright/build`, change `IMAGE_TOOL=<toolname>`)

- [ ] **`docker/<toolname>/README.md`** — document:
  - Image purpose and base image
  - Build args (if any)
  - Usage example
  - Docker Hub tag

- [ ] **`bin/utils/common.sh`** — add image constant:
  ```bash
  MEC_IMAGE_<TOOLNAME>="${MEC_IMAGE_<TOOLNAME>:-${MEC_IMAGE_REPO}:<toolname>-${MEC_IMAGE_TAG}}"
  ```
  Export it in the export block below the other image constants.

- [ ] **`bin/<toolname>`** — use `check_custom_image "$MEC_IMAGE_<TOOLNAME>"` instead of a bare public image; set `IMAGE=${IMAGE:-"$MEC_IMAGE_<TOOLNAME>"}"`

- [ ] **`CLAUDE.md`** — add the tool to the `docker/` listing in Key Directories

- [ ] **Docker Hub** — build and push:
  ```bash
  cd docker/<toolname>
  ./build        # local build
  # For CI push: PUSH=true CI=true ./build
  ```

- [ ] **GitHub Actions** — add a Docker build workflow if not already covered by the existing matrix build

---

## Scenario C — Version variant of an existing tool

Adding a new version alias (e.g. `node26`, `npm24`) alongside an existing tool.

### Checklist

- [ ] **`bin/<toolname><version>`** — copy the existing variant script (e.g. `bin/node24`) and update the image tag only (e.g. `node:26-alpine`)
- [ ] **`setup.sh`** — add the new version to the existing tool's `install_` / `uninstall_` function, following the pattern of existing variants
- [ ] **`bin/mec`** — add the variant name to the tool dispatch case block (search for `# Tool wrappers`)
- [ ] **`mec help`** — update the TOOLS section entry for the tool group (e.g. `node, node20/22/24/26`)
- [ ] **`README.md`** — update the version table for the tool

No new test file needed if the variant follows the exact same pattern — add a test case to the existing `tests/unit/test-<toolname>.bats` instead.

---

## Scenario D — Complex refactor / multi-tool change

If the work involves multiple tools, architecture changes, or modifying shared utilities:

1. **Do not implement directly** — the scope is too broad for a single guided checklist.
2. Summarize what the user wants to achieve.
3. Use the planning skill: `superpowers:writing-plans`
4. The plan should break the work into discrete GH issues (one per tool or concern) and a milestone if applicable.

---

## Step 2 — Execute

Work through the checklist top to bottom. After each file change, state a one-liner (what was changed and why).

Per `preferences.md`:
- ALWAYS prefer editing existing files over creating new ones
- NEVER create files unless necessary

---

## Step 3 — Verify

Before committing:

```bash
# Syntax check
bash -n bin/<toolname>

# Smoke test (Docker must be available)
./bin/mec <toolname> --help || ./bin/<toolname> --help

# Run unit tests
bats tests/unit/test-<toolname>.bats
```

---

## Step 4 — Commit

Run `git log --oneline -5` first. Per `git-workflow.md`:
- **Amend** if this is a correction to the current branch's ongoing work
- **New commit** (`feat: add <toolname> wrapper (#<issue>)`) if standalone

Push with explicit branch: `git push origin <branch-name>`

---

## Output

```
add-mec-tool complete.

Scenario:    <A | B | C | D>
Tool:        <toolname>
Files added: <list>
Files changed: <list>

Committed: <yes — <hash> | no>

Next: run claudemd-streamline if CLAUDE.md was updated, to check for duplication.
```

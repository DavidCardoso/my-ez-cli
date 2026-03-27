---
name: claudemd-streamline
description: Use when CLAUDE.md files may have drifted from .claude/rules/, contain sections now duplicated in rules files, reference removed tools or outdated patterns, or when rules files were recently added/changed and CLAUDE.md hasn't been reviewed.
---

# CLAUDE.md Streamline

## Overview

Claude Code auto-loads CLAUDE.md files from multiple locations (global `~/.claude/CLAUDE.md`, project root, and any subdirectory the session touches). Over time these files accumulate content that duplicates `.claude/rules/` files or becomes stale as the codebase evolves. This skill audits all active CLAUDE.md files, removes duplication, replaces covered sections with pointers, and trims stale content.

**Announce at start:** "Running claudemd-streamline: auditing CLAUDE.md files against rules and codebase."

## Step 1 — Locate all active CLAUDE.md files

Check the following locations (skip if file doesn't exist):

```bash
# Global
~/.claude/CLAUDE.md

# Project root
./CLAUDE.md

# Subdirectories (any CLAUDE.md Claude Code would auto-load for this project)
find . -name "CLAUDE.md" -not -path "./.git/*"
```

Also check for `CLAUDE.local.md` variants in the same locations (these are gitignored machine-local overrides).

List all found files before proceeding.

## Step 2 — Audit each CLAUDE.md for duplication

For each file, compare its sections against `.claude/rules/*.md`:

- Read the CLAUDE.md section headings and key rules
- Grep `.claude/rules/*.md` for matching topic keywords
- Flag any section where the rules file is now the authoritative source

**Duplication patterns to look for:**
- Contribution guidelines / branch naming → likely overlaps `git-workflow.md`
- Test requirements / run-before-commit → likely overlaps `code-standards.md`
- Script patterns / smoke test → likely overlaps `shell-standards.md`
- Python conventions → likely overlaps `python-standards.md`
- Documentation location / plan mode / file handling → likely overlaps `preferences.md`

Build a table per file:

| Section | Status | Action |
|---------|--------|--------|
| "Contributing" | Duplicates git-workflow.md | Replace with pointer |
| "Core Architecture" | Unique — codebase reference | Keep |
| "Adding New Tools" | Unique — how-to guide | Keep |

## Step 3 — Audit each CLAUDE.md for staleness

Check sections that reference concrete codebase facts against actual state:

- **File paths and directory names** — do they still exist? (`ls` or `find` to verify)
- **Tool names and scripts** — still present in `bin/`?
- **Docker images / Dockerfiles** — still in `docker/`?
- **Service names** — still in `services/`?
- **External doc links** (e.g. `docs/AI_INTEGRATION.md`) — do the files exist?

Flag anything that references a path or artifact that no longer exists.

## Step 4 — Classify and act

For each flagged item, apply this decision tree:

```
Is the section fully covered by a .claude/rules/ file?
  YES → Replace section content with a one-line pointer:
        > See .claude/rules/<file>.md

Is the section partially covered (some unique content remains)?
  YES → Keep only the unique content; add pointer for the covered part.

Is the section stale (references removed/renamed artifacts)?
  YES → Update to match current state, or delete if the whole section is obsolete.

Is the section unique and accurate?
  → Keep as-is. No action.
```

**Pointer format** (use consistently):
```markdown
> Covered in [`.claude/rules/git-workflow.md`](.claude/rules/git-workflow.md)
```

**Global `~/.claude/CLAUDE.md` special rule:** This file should contain only machine-local or cross-project preferences. If it contains anything project-specific, move it to the project's CLAUDE.md or `.claude/rules/` and clear it from the global file.

## Step 5 — Execute

Make all edits. Per `preferences.md`:
- ALWAYS prefer editing existing files over creating new ones
- NEVER delete a section without verifying it's truly covered or stale

State a one-liner after each edit (what changed and why).

## Step 6 — Commit

Run `git log --oneline -5` first. Ask: do these changes correct, adjust, or extend work already in the most recent commit on this branch? If yes → amend. Only create a new commit if this is the first `.claude/` change on the branch or a fully independent concern.

- **Amend** if the branch already has a `.claude/` cleanup commit this work builds on
- **New commit** (`chore: streamline CLAUDE.md files`) if standalone

Push with explicit branch: `git push origin <branch-name>`

## Output

Print a summary when done:

```
CLAUDE.md streamline complete.

Files reviewed:     <list>
Sections replaced with pointers: <list or "none">
Sections removed (stale):        <list or "none">
Sections kept (unique):          <count>

Committed: <yes — <hash> | no>

Next: run memory-migration if session feedback has also accumulated.
```

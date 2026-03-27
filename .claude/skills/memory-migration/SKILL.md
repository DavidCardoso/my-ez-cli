---
name: memory-migration
description: Use when home-folder Claude Code memory has drifted from the project repo memory, when feedback files have accumulated in ~/.claude/projects/ that haven't been triaged, or when preparing to close out a branch and wanting to promote patterns into permanent rules.
---

# Memory Migration

## Overview

Claude Code stores memory in two locations: the home folder (`~/.claude/projects/<slug>/memory/`) which loads automatically each session, and the project repo (`.claude/memory/`) which travels with the repo and is version-controlled. Over time these drift apart. This skill audits the gap, classifies each out-of-sync file, and executes the right action: promote to a rules file, sync to repo memory, or delete.

**Announce at start:** "Running memory-migration: auditing home-folder vs repo memory."

## Step 1 — Derive paths

```bash
HOME_SLUG=$(pwd | sed 's|/|-|g' | sed 's|^-||')
HOME_MEMORY="$HOME/.claude/projects/$HOME_SLUG/memory"
REPO_MEMORY=".claude/memory"
RULES_DIR=".claude/rules"
```

## Step 2 — Audit

List files in both locations (excluding `MEMORY.md`):

```bash
ls "$HOME_MEMORY"/*.md 2>/dev/null | xargs -n1 basename | grep -v MEMORY.md | sort
ls "$REPO_MEMORY"/*.md 2>/dev/null | xargs -n1 basename | grep -v MEMORY.md | sort
```

Build a comparison table:

| File | In home | In repo | Covered by rule? |
|------|---------|---------|-----------------|

For "covered by rule?" — grep all `.claude/rules/*.md` files for the memory's topic or `name:` frontmatter value.

## Step 3 — Classify each out-of-sync file

Apply this decision tree to every file not present in both locations:

```
Is the content a generalizable coding/workflow standard (applies every session)?
  YES → Promote to .claude/rules/
        Does a thematically matching rule file already exist?
          YES → Merge section into that file
          NO  → Create new .claude/rules/<topic>.md
        Then delete the memory file from both locations.

Is it project-specific context (why this project works a certain way)?
  YES → Sync to .claude/memory/ (repo). Mirror to home folder.

Is it a deferred backlog item or note already captured in docs/ or ROADMAP.md?
  YES → Delete from home folder only. Do not add to repo.

Is it already fully covered by an existing rules file or memory file?
  YES → Delete the redundant copy from home folder.
```

**Merge targets** (established pattern from this project):
- commit / push / branch / rebase feedback → `git-workflow.md`
- test / coverage / smoke feedback → `code-standards.md`
- shell / bin / script / mec CLI feedback → `shell-standards.md`
- python / type hints / pydantic feedback → `python-standards.md`

**Rules section format** (must match existing style):
```markdown
## <Rule title>

<What to do — imperative, present tense>

**Why:** <one concrete incident or reason>

**How to apply:** <specific instructions or checklist>
```

## Step 4 — Execute

Take all classified actions. Per `preferences.md`:
- ALWAYS prefer editing existing files over creating new ones
- NEVER create files unless necessary

State a one-liner after each action (what was done and why).

## Step 5 — Sync MEMORY.md

Repo `.claude/memory/MEMORY.md` is the source of truth. Home-folder `MEMORY.md` is a derived mirror.

1. Update repo `MEMORY.md` — add/remove entries to reflect changes
2. Overwrite home-folder `MEMORY.md` with the repo content, prepending this header:

```markdown
# Memory Index

> Source of truth is in the project repo at `.claude/memory/MEMORY.md`.
> Files below are mirrored here so they load on any machine via the home-folder path.
```

Entry format: `- [filename.md](./filename.md) — <one-line summary>`

Also copy any new/changed repo memory files to the home-folder path, and remove files deleted from repo memory.

## Step 6 — Commit

Group all `.claude/` changes into one logical commit. Per `git-workflow.md`:
- **Amend** if this migration is a correction/adjustment to the current branch's ongoing work
- **New commit** (`chore: sync Claude Code memory and rules`) if this is standalone cleanup

Push with explicit branch: `git push origin <branch-name>`

## Output

Print a summary when done:

```
Memory migration complete.

Promoted to rules:      <list or "none">
Added to repo memory:   <list or "none">
Deleted (stale/covered): <list or "none">
MEMORY.md:              synced (repo → home)

Committed: <yes — <hash> | no>
```

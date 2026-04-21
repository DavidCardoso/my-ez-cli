---
name: Validate patterns against industry standards before recommending
description: Always verify new naming conventions, patterns, or tooling choices against industry standards before recommending them
type: feedback
---

Before recommending a new pattern (branch prefix, naming convention, tool, workflow) for this project, verify it against an authoritative industry standard first.

**Why:** When asked to fix the branch naming convention, `improve` was initially recommended and justified as appropriate for styling work — without checking it against Conventional Commits or any other standard. When the user asked for proof, the recommendation was reversed immediately. This is backwards: the verification should happen before the recommendation, not after being challenged.

**How to apply:**
- Branch prefixes, commit types → verify against [Conventional Commits](https://www.conventionalcommits.org/) before suggesting
- Tool versions, security patterns → check official docs or CVE databases first
- If uncertain whether something is standard, say so upfront and look it up before recommending
- Never justify a non-standard pattern as "correct" without a citation; if it's a deviation from standard, name it as such

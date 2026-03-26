# User Preferences

**Note**: Communication preferences (verbosity, tone, emoji usage) are configured in `.claude/settings.json`

## Documentation

**Location**: All documentation MUST live in `docs/` folder
- Never create documentation files in project subdirectories
- Never create ad-hoc documentation like MIGRATION.md, NOTES.md without explicit request
- Use existing documentation files when relevant (CODE_STANDARDS.md, AI_INTEGRATION.md, etc.)

## Plan Mode

Activate plan mode before:
- Architecture decisions
- Implementing new features
- NOT for small refactoring tasks

## File Handling

- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files to creating new ones
- This includes markdown files

## Model Usage

**Default**: Sonnet (configured in settings.json)
- Use for: most tasks including refactoring, debugging, feature implementation

**Override to Opus**: Rarely needed
- Most complex reasoning only
- Override: `claude --model opus`

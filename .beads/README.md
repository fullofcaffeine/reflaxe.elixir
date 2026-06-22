# Beads - AI-Native Issue Tracking

Welcome to Beads! This repository uses **Beads** for issue tracking - a modern, AI-native tool designed to live directly in your codebase alongside your code.

## What is Beads?

Beads is issue tracking that lives in your repo, making it perfect for AI coding agents and developers who want their issues close to their code. No web UI required - everything works through the CLI and integrates seamlessly with git.

**Learn more:** [github.com/steveyegge/beads](https://github.com/steveyegge/beads)

## Quick Start

### Essential Commands

```bash
# Create new issues
bd create "Add user authentication"

# View all issues
bd list

# View issue details
bd show <issue-id>

# Update issue status
bd update <issue-id> --status in-progress
bd close <issue-id>

# Fresh clone or missing local database
bd bootstrap --yes

# Manually refresh the tracked JSONL export if needed
bd export > .beads/issues.jsonl
```

### Working with Issues

Issues in Beads are:
- **Git-native**: Exported to `.beads/issues.jsonl` and committed like source
- **AI-friendly**: CLI-first design works perfectly with AI coding agents
- **Branch-aware**: Issues can follow your branch workflow
- **Reviewable**: Issue changes appear in normal git diffs and commits

### Repository Workflow

This repository uses Beads with an embedded Dolt local working store. It does
not configure a shared Dolt remote. The tracked `.beads/issues.jsonl` file is
the portable export used for code review and fresh-clone bootstrap.

Run `bd bootstrap --yes` after a fresh clone if `bd` cannot see issues yet. The
repo pre-commit hook exports the local Beads database to `.beads/issues.jsonl`
before running path, secret, formatter, and naming guards. You can also run
`bd export > .beads/issues.jsonl` manually before committing issue changes.

The installed `bd` 1.0.x CLI used here does not provide the older top-level
`bd sync` command.

## Why Beads?

✨ **AI-Native Design**
- Built specifically for AI-assisted development workflows
- CLI-first interface works seamlessly with AI coding agents
- No context switching to web UIs

🚀 **Developer Focused**
- Issues live in your repo, right next to your code
- Works offline, syncs when you push
- Fast, lightweight, and stays out of your way

🔧 **Git Integration**
- Reviewable issue exports with git commits
- Branch-aware issue tracking
- Intelligent JSONL merge resolution

## Get Started with Beads

Try Beads in your own projects:

```bash
# Install Beads
curl -sSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Initialize in your repo
bd init

# Create your first issue
bd create "Try out Beads"
```

## Learn More

- **Documentation**: [github.com/steveyegge/beads/docs](https://github.com/steveyegge/beads/tree/main/docs)
- **Quick Start Guide**: Run `bd quickstart`
- **Examples**: [github.com/steveyegge/beads/examples](https://github.com/steveyegge/beads/tree/main/examples)

---

*Beads: Issue tracking that moves at the speed of thought* ⚡

# CODITECT Distribution System

## Purpose

This repository hosts the **installer and updater** for the CODITECT AI-Powered Development Framework. It provides one-click installation with automatic updates for end users.

## Repository Role

This is the **distribution layer**, not the content layer:

- **This repo** (`coditect-ai/coditect-ops-distribution`): Installer scripts, auto-updater, documentation
- **Content repo** (`coditect-ai/coditect-core-dotclaude`): Agents, commands, skills, scripts

## Scripts

### install.sh
One-click installer that:
1. Clones `coditect-core-dotclaude` to `/opt/coditect`
2. Sets read-only permissions (users can't modify)
3. Creates `~/.coditect` symlink for user access
4. Adds scripts to PATH
5. Sets up daily auto-updates via launchd
6. Integrates with Claude Code (`~/.claude/`)

### update.sh
Auto-updater that:
1. Runs daily at 9:00 AM via launchd
2. Pulls latest from `coditect-core-dotclaude`
3. Resets permissions
4. Sends macOS notification on update

### uninstall.sh
Clean removal that:
1. Removes `/opt/coditect`
2. Removes symlinks and PATH entries
3. Stops auto-updater daemon
4. Creates backups of modified shell configs

## End User Commands

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/coditect-ai/coditect-ops-distribution/main/install.sh | bash

# Uninstall
curl -fsSL https://raw.githubusercontent.com/coditect-ai/coditect-ops-distribution/main/uninstall.sh | bash

# Manual update
/opt/coditect/update.sh
```

## Architecture

```
End User Machine:
├── /opt/coditect/          # Read-only installation (coditect-core-dotclaude)
│   ├── agents/             # 46 AI agents
│   ├── commands/           # 72 slash commands
│   ├── skills/             # 189 skills
│   ├── scripts/            # Utility scripts (including export-dedup.py)
│   └── ...
│
├── ~/.coditect -> /opt/coditect    # User access symlink
│
└── ~/.claude/              # Claude Code integration
    ├── CLAUDE.md -> /opt/coditect/CLAUDE.md
    ├── commands -> /opt/coditect/commands
    ├── skills -> /opt/coditect/skills
    └── agents -> /opt/coditect/agents
```

## Administrator Workflow

### Pushing Updates

Updates to `coditect-core-dotclaude` automatically propagate to all users:

1. Make changes in `coditect-core-dotclaude`
2. Commit and push to main branch
3. Users receive update at next daily check (9:00 AM)

### Testing Before Release

```bash
# Test on staging branch
CODITECT_BRANCH=staging curl -fsSL https://raw.githubusercontent.com/coditect-ai/coditect-ops-distribution/main/install.sh | bash
```

### Version Pinning

For enterprise users who need stability:

```bash
# Pin to specific tag
CODITECT_BRANCH=v1.0.0 curl -fsSL https://raw.githubusercontent.com/coditect-ai/coditect-ops-distribution/main/install.sh | bash
```

## Security Model

- **Root ownership**: Files owned by root, not modifiable by users
- **Read-only access**: Users can read/execute but not modify
- **Centralized updates**: Only administrators can push changes
- **Audit trail**: Git history tracks all changes

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODITECT_REPO` | `coditect-ai/coditect-core-dotclaude` | Source repository |
| `CODITECT_BRANCH` | `main` | Branch to install |

## Maintenance

### Updating Installer Scripts

When modifying install.sh, update.sh, or uninstall.sh:

```bash
cd /path/to/coditect
# Make changes
git add -A
git commit -m "Description of changes"
git push origin main
```

### Monitoring

Check auto-updater logs:
```bash
cat /tmp/coditect-updater.log
```

## Related Repositories

- **coditect-core-dotclaude**: Main content (agents, commands, skills)
- **coditect-rollout-master**: Master orchestration repository

---

**Owner**: AZ1.AI INC
**Maintainer**: Hal Casteel

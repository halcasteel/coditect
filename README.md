# CODITECT

AI-Powered Development Framework - System-wide distribution with automatic updates.

## One-Click Installation

```bash
curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/install.sh | bash
```

## What Gets Installed

- **Location**: `/opt/coditect` (read-only, admin-controlled)
- **User symlink**: `~/.coditect`
- **Claude integration**: `~/.claude/` (commands, skills, agents)
- **Auto-updates**: Daily at 9:00 AM via launchd

## Features

- **46 specialized AI agents** for development tasks
- **72 slash commands** for Claude Code
- **189 reusable skills** for automation
- **Export deduplication** for context management
- **Multi-agent orchestration** capabilities

## Usage

### In Any Project
```bash
# Create project-specific symlink
ln -s ~/.coditect .coditect
```

### Manual Update
```bash
/opt/coditect/update.sh
```

### Check Version
```bash
git -C /opt/coditect log -1 --oneline
```

## For Administrators

### Push Updates
Updates are automatically distributed to all users daily at 9:00 AM.

```bash
# Make changes to this repo
git add . && git commit -m "Update description" && git push
```

### Override Installation
```bash
# Different branch
CODITECT_BRANCH=develop curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/install.sh | bash

# Different repo
CODITECT_REPO=https://github.com/your-org/coditect-fork.git curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/uninstall.sh | bash
```

This removes:
- `/opt/coditect` installation
- `~/.coditect` symlink
- Auto-updater daemon
- Claude Code symlinks
- PATH entries (creates backup)

## Architecture

```
/opt/coditect/              # System-wide (read-only)
├── install.sh              # Installer
├── update.sh               # Auto-updater
├── CLAUDE.md               # Main config
├── agents/                 # 46 AI agents
├── commands/               # 72 slash commands
├── skills/                 # 189 skills
├── scripts/                # Utility scripts
└── orchestration/          # Multi-agent coordination

~/.coditect -> /opt/coditect   # User symlink
~/.claude/                      # Claude Code integration
├── CLAUDE.md -> /opt/coditect/CLAUDE.md
├── commands -> /opt/coditect/commands
├── skills -> /opt/coditect/skills
└── agents -> /opt/coditect/agents
```

## License

Proprietary - All rights reserved.

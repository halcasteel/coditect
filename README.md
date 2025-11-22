# coditect-ops-distribution

**Operations Repository - AZ1.AI CODITECT Ecosystem**

---

## Overview

The primary distribution mechanism for CODITECT, providing one-click installation with license validation and automatic updates. This repository contains the installer scripts, auto-updater daemon, and documentation that enables users to deploy CODITECT to their systems with minimal effort while maintaining license compliance and receiving automatic updates.

**Status:** Production
**Category:** ops
**Priority:** P0

---

## Purpose

### What Problem This Solves

- **One-Click Installation**: Deploy CODITECT with a single curl command
- **License Validation**: Ensure only licensed users can install and use CODITECT
- **Automatic Updates**: Keep all installations current without user intervention
- **System-wide Deployment**: Install to /opt for multi-user environments
- **Claude Code Integration**: Automatic symlinks for Claude Code compatibility

### Who Uses It

- **End Users**: Installing CODITECT on their machines
- **Enterprise IT**: Deploying CODITECT across organizations
- **Operators**: Managing CODITECT installations
- **Administrators**: Pushing updates to all users

### Ecosystem Role

This repository is the **distribution layer** that separates installer scripts from content. It pulls content from `coditect-core` and provides the infrastructure for installation, updates, and license validation. This is how users get CODITECT onto their systems.

---

## Key Features

- **One-Click Installer** - Single curl command installation
- **License Validation** - API-based license verification
- **Hardware Fingerprinting** - Prevent unauthorized license sharing
- **Automatic Updates** - Daily updates via launchd (macOS)
- **Read-Only Installation** - Users cannot modify system files
- **Claude Code Integration** - Automatic symlink setup
- **Offline Grace Period** - Works without internet temporarily
- **Clean Uninstall** - Complete removal with backup

---

## Technology Stack

- **Installer:** Bash shell scripts
- **Scheduler:** launchd (macOS) / systemd (Linux)
- **License API:** REST API calls with curl
- **Notifications:** macOS notification center
- **Version Control:** Git

---

## Quick Start

### One-Click Installation

```bash
# Install CODITECT (requires license key)
curl -fsSL https://az1.ai/install | bash
```

### Installation with License Key

```bash
# Provide license key via environment variable
CODITECT_LICENSE=YOUR-LICENSE-KEY curl -fsSL https://az1.ai/install | bash
```

### Manual Update

```bash
/opt/coditect/update.sh
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/coditect-ai/coditect-ops-distribution/main/uninstall.sh | bash
```

---

## What Gets Installed

### System Locations

- **Installation**: `/opt/coditect` (read-only, admin-controlled)
- **User Symlink**: `~/.coditect`
- **Claude Integration**: `~/.claude/`
- **License File**: `~/.coditect-license`
- **Auto-updater**: `~/Library/LaunchAgents/com.coditect.updater.plist`

### CODITECT Content

- **46 Specialized AI Agents** - Development task automation
- **72 Slash Commands** - Claude Code workflows
- **189 Reusable Skills** - Automation capabilities
- **Export Deduplication** - Context management
- **Multi-agent Orchestration** - Complex workflow coordination

---

## Directory Structure

```
coditect-ops-distribution/
├── .coditect -> ../../../.coditect    # Distributed intelligence symlink
├── .claude -> .coditect               # Claude Code compatibility
├── install.sh                         # Main installer script
├── update.sh                          # Auto-updater script
├── uninstall.sh                       # Clean removal script
├── CLAUDE.md                          # Distribution system docs
├── bin/                               # Utility scripts
├── commands/                          # Installer commands
├── diagrams/                          # Architecture diagrams
├── docs/                              # Documentation
│   └── LICENSE-FLOW.md                # License validation flow
├── installer/                         # Installer components
│   ├── validate-license.sh
│   ├── setup-launchd.sh
│   └── setup-claude.sh
└── README.md                          # This file
```

---

## Distributed Intelligence

This repository is part of the CODITECT distributed intelligence architecture:

```
.coditect -> ../../../.coditect  # Links to master brain
.claude -> .coditect             # Claude Code compatibility
```

**Benefits:**
- Access to 50 specialized AI agents
- 72 slash commands available
- 24 reusable skills
- Consistent development patterns

**Learn more:** [WHAT-IS-CODITECT.md](https://github.com/coditect-ai/coditect-core/blob/main/WHAT-IS-CODITECT.md)

---

## Architecture

### Installation Flow

```
┌─────────────────────────────────────────┐
│  1. User runs curl installer command     │
├─────────────────────────────────────────┤
│  2. Check dependencies (git, curl)       │
├─────────────────────────────────────────┤
│  3. Prompt for license key               │
├─────────────────────────────────────────┤
│  4. Validate license with API            │
│     POST /api/v1/licenses/validate       │
├─────────────────────────────────────────┤
│  5. Clone coditect-core        │
│     to /opt/coditect                     │
├─────────────────────────────────────────┤
│  6. Set read-only permissions            │
├─────────────────────────────────────────┤
│  7. Create user symlinks                 │
│     ~/.coditect -> /opt/coditect         │
├─────────────────────────────────────────┤
│  8. Setup Claude Code integration        │
│     ~/.claude/{CLAUDE.md, commands, ...} │
├─────────────────────────────────────────┤
│  9. Install auto-updater daemon          │
│     Daily at 9:00 AM                     │
└─────────────────────────────────────────┘
```

### File System Layout

```
End User Machine:
├── /opt/coditect/              # Read-only installation
│   ├── CLAUDE.md               # Main configuration
│   ├── agents/                 # 46 AI agents
│   ├── commands/               # 72 slash commands
│   ├── skills/                 # 189 skills
│   ├── scripts/                # Utility scripts
│   └── orchestration/          # Multi-agent coordination
│
├── ~/.coditect -> /opt/coditect    # User symlink
├── ~/.coditect-license             # License key file
│
└── ~/.claude/                  # Claude Code integration
    ├── CLAUDE.md -> /opt/coditect/CLAUDE.md
    ├── commands -> /opt/coditect/commands
    ├── skills -> /opt/coditect/skills
    └── agents -> /opt/coditect/agents
```

---

## Integration with CODITECT Platform

### Dependencies

- [coditect-core](../core/coditect-core) - Content source (agents, commands, skills)
- [coditect-ops-license](./coditect-ops-license) - License validation API
- [coditect-legal](../docs/coditect-legal) - EULA and ToS acceptance

### Dependents

- End users installing CODITECT
- Enterprise deployments
- [coditect-cloud-backend](../cloud/coditect-cloud-backend) - Tracks installations

### Repository Relationship

This is the **distribution layer**, not the content layer:

- **This repo** (`coditect-ops-distribution`): Installer scripts, updater, docs
- **Content repo** (`coditect-core`): Actual agents, commands, skills

---

## License Validation

### Validation Flow

```bash
# License validation API call
curl -X POST https://api.az1.ai/api/v1/licenses/validate \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "CODITECT-PILOT-XXXX-XXXX",
    "action": "install",
    "machine_id": "hostname"
  }'
```

### Response Codes

| Code | Status | Action |
|------|--------|--------|
| 200 | Valid | Proceed with installation |
| 401 | Invalid | Exit with error |
| 402 | Expired | Prompt for renewal |
| 5xx | Server Error | Try offline mode |

### Offline Grace Period

If the license server is unreachable, installations with a valid local license file can continue for 72 hours.

---

## Auto-Update System

### launchd Configuration

Updates run daily at 9:00 AM via macOS launchd:

```xml
<!-- ~/Library/LaunchAgents/com.coditect.updater.plist -->
<dict>
    <key>Label</key>
    <string>com.coditect.updater</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/coditect/update.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
```

### Update Process

1. Pull latest from `coditect-core`
2. Reset file permissions
3. Send macOS notification on success
4. Log results to `/tmp/coditect-updater.log`

---

## Administrator Guide

### Pushing Updates

Updates to `coditect-core` automatically propagate to all users:

```bash
# Make changes in coditect-core
cd /path/to/coditect-core
git add . && git commit -m "Update description" && git push
# Users receive update at next daily check (9:00 AM)
```

### Testing Before Release

```bash
# Test on staging branch
CODITECT_BRANCH=staging curl -fsSL https://az1.ai/install | bash
```

### Version Pinning

For enterprise users who need stability:

```bash
# Pin to specific tag
CODITECT_BRANCH=v1.0.0 curl -fsSL https://az1.ai/install | bash
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODITECT_LICENSE` | - | License key (skips prompt) |
| `CODITECT_REPO` | `coditect-ai/coditect-core` | Source repository |
| `CODITECT_BRANCH` | `main` | Branch to install |
| `CODITECT_API` | `https://api.az1.ai/api/v1` | License API URL |

---

## Security Model

### Protection Mechanisms

- **Root Ownership**: Files owned by root, not modifiable by users
- **Read-Only Access**: Users can read/execute but not modify
- **License Binding**: Hardware fingerprinting prevents key sharing
- **Centralized Updates**: Only administrators can push changes
- **Audit Trail**: Git history tracks all changes

### License Security

- License keys transmitted over HTTPS only
- Hardware fingerprints hashed (SHA-256)
- Server-side activation limits
- License revocation capability

---

## Usage Commands

### In Any Project

```bash
# Create project-specific symlink
ln -s ~/.coditect .coditect
```

### Check Version

```bash
git -C /opt/coditect log -1 --oneline
```

### View Update Logs

```bash
cat /tmp/coditect-updater.log
```

### Force Update

```bash
/opt/coditect/update.sh
```

---

## Troubleshooting

### Common Issues

**License validation failed:**
- Check internet connection
- Verify license key is correct
- Ensure license is not expired

**Permission denied during installation:**
- Installer requires sudo for /opt access
- Check that you have admin privileges

**Updates not running:**
- Verify launchd agent is loaded: `launchctl list | grep coditect`
- Check logs: `cat /tmp/coditect-updater.log`
- Reload agent: `launchctl load ~/Library/LaunchAgents/com.coditect.updater.plist`

**Claude Code not finding CODITECT:**
- Verify symlinks exist: `ls -la ~/.claude/`
- Check that `~/.coditect` points to `/opt/coditect`

---

## Related Resources

- **Master Repository:** [coditect-rollout-master](https://github.com/coditect-ai/coditect-rollout-master)
- **Content Repository:** [coditect-core](https://github.com/coditect-ai/coditect-core)
- **License Manager:** [coditect-ops-license](https://github.com/coditect-ai/coditect-ops-license)
- **Get License:** [az1.ai/coditect](https://az1.ai/coditect)

---

## Contributing

1. Fork the repository
2. Create feature branch
3. Test installation thoroughly
4. Update documentation
5. Submit pull request

For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

Copyright (C) 2025 AZ1.AI INC. All Rights Reserved.

**PROPRIETARY AND CONFIDENTIAL** - This repository contains AZ1.AI INC. trade secrets and confidential information. Unauthorized copying, transfer, or use is strictly prohibited.

---

**Owner:** AZ1.AI INC
**Maintainer:** Hal Casteel

*Built with Excellence by AZ1.AI CODITECT*
*Systematic Development. Continuous Context. Exceptional Results.*

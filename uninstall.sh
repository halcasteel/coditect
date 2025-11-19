#!/bin/bash
#
# CODITECT Uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/uninstall.sh | bash
#
set -e

# Configuration
INSTALL_DIR="/opt/coditect"
USER_LINK="$HOME/.coditect"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.coditect.updater.plist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo -e "${RED}=============================================${NC}"
echo -e "${RED}        CODITECT UNINSTALLER${NC}"
echo -e "${RED}=============================================${NC}"
echo ""

# Confirm
read -p "Are you sure you want to uninstall CODITECT? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop and remove auto-updater
if [ -f "$LAUNCHD_PLIST" ]; then
    log_info "Removing auto-updater..."
    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    rm -f "$LAUNCHD_PLIST"
fi

# Remove Claude integration symlinks
log_info "Removing Claude Code integration..."
rm -f "$HOME/.claude/CLAUDE.md" 2>/dev/null || true
rm -f "$HOME/.claude/commands" 2>/dev/null || true
rm -f "$HOME/.claude/skills" 2>/dev/null || true
rm -f "$HOME/.claude/agents" 2>/dev/null || true

# Remove user symlink
if [ -L "$USER_LINK" ]; then
    log_info "Removing user symlink..."
    rm -f "$USER_LINK"
elif [ -d "$USER_LINK" ]; then
    log_warn "~/.coditect is a directory, not a symlink. Skipping."
fi

# Remove installation
if [ -d "$INSTALL_DIR" ]; then
    log_info "Removing installation from $INSTALL_DIR..."
    sudo rm -rf "$INSTALL_DIR"
fi

# Remove PATH from shell config
for config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$config" ] && grep -q "coditect/scripts" "$config"; then
        log_info "Removing PATH from $config..."
        # Create backup
        cp "$config" "${config}.coditect-backup"
        # Remove CODITECT lines
        grep -v "coditect" "$config" > "${config}.tmp" && mv "${config}.tmp" "$config"
    fi
done

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   CODITECT UNINSTALLED SUCCESSFULLY${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Removed:"
echo "  - $INSTALL_DIR"
echo "  - $USER_LINK"
echo "  - Auto-updater daemon"
echo "  - Claude Code symlinks"
echo "  - PATH entries (backup created)"
echo ""
echo "To reinstall:"
echo "  curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/install.sh | bash"
echo ""

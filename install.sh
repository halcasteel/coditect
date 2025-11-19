#!/bin/bash
#
# CODITECT One-Click Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/halcasteel/coditect/main/install.sh | bash
#
set -e

# Configuration
CODITECT_REPO="${CODITECT_REPO:-https://github.com/halcasteel/coditect.git}"
CODITECT_BRANCH="${CODITECT_BRANCH:-main}"
INSTALL_DIR="/opt/coditect"
USER_LINK="$HOME/.coditect"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.coditect.updater.plist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "============================================="
    echo "        CODITECT INSTALLER v1.0"
    echo "   AI-Powered Development Framework"
    echo "============================================="
    echo -e "${NC}"
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v git &> /dev/null; then
        log_error "git is required but not installed."
        exit 1
    fi

    log_info "Dependencies OK"
}

install_coditect() {
    log_info "Installing CODITECT to $INSTALL_DIR..."

    # Determine if sudo is needed
    if [ -w "/opt" ] 2>/dev/null; then
        SUDO=""
    else
        SUDO="sudo"
        log_info "Administrator privileges required..."
    fi

    # Clone or update
    if [ -d "$INSTALL_DIR/.git" ]; then
        log_info "Updating existing installation..."
        $SUDO git -C "$INSTALL_DIR" fetch origin
        $SUDO git -C "$INSTALL_DIR" reset --hard "origin/$CODITECT_BRANCH"
        $SUDO git -C "$INSTALL_DIR" submodule update --init --recursive
    else
        log_info "Fresh installation..."
        $SUDO rm -rf "$INSTALL_DIR"
        $SUDO git clone --branch "$CODITECT_BRANCH" --recurse-submodules "$CODITECT_REPO" "$INSTALL_DIR"
    fi

    # Set permissions (read-only for users)
    log_info "Setting permissions..."
    $SUDO chown -R root:staff "$INSTALL_DIR" 2>/dev/null || true
    $SUDO chmod -R 755 "$INSTALL_DIR"
    $SUDO find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    $SUDO find "$INSTALL_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod 755 {} \;

    log_info "Installation complete"
}

create_user_symlink() {
    log_info "Creating user symlink at $USER_LINK..."

    if [ -L "$USER_LINK" ]; then
        rm "$USER_LINK"
    elif [ -d "$USER_LINK" ]; then
        log_warn "Backing up existing $USER_LINK to ${USER_LINK}.backup"
        mv "$USER_LINK" "${USER_LINK}.backup"
    fi

    ln -s "$INSTALL_DIR" "$USER_LINK"
    log_info "Symlink created: $USER_LINK -> $INSTALL_DIR"
}

setup_path() {
    log_info "Setting up PATH..."

    SHELL_CONFIG=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi

    if [ -n "$SHELL_CONFIG" ]; then
        PATH_EXPORT='export PATH="$HOME/.coditect/scripts:$PATH"'

        if ! grep -q "coditect/scripts" "$SHELL_CONFIG" 2>/dev/null; then
            echo "" >> "$SHELL_CONFIG"
            echo "# CODITECT" >> "$SHELL_CONFIG"
            echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
            log_info "Added CODITECT to PATH in $SHELL_CONFIG"
        else
            log_info "PATH already configured"
        fi
    else
        log_warn "Could not find shell config. Add to your shell config:"
        echo "  export PATH=\"\$HOME/.coditect/scripts:\$PATH\""
    fi
}

setup_auto_updater() {
    log_info "Setting up auto-updater..."

    mkdir -p "$HOME/Library/LaunchAgents"

    cat > "$LAUNCHD_PLIST" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
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
    <key>StandardOutPath</key>
    <string>/tmp/coditect-updater.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/coditect-updater.log</string>
</dict>
</plist>
PLIST

    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    launchctl load "$LAUNCHD_PLIST"

    log_info "Auto-updater configured (daily at 9:00 AM)"
}

setup_claude_integration() {
    log_info "Setting up Claude Code integration..."

    mkdir -p "$HOME/.claude"

    # Symlink key files
    [ -f "$INSTALL_DIR/CLAUDE.md" ] && ln -sf "$INSTALL_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    [ -d "$INSTALL_DIR/commands" ] && ln -sf "$INSTALL_DIR/commands" "$HOME/.claude/commands"
    [ -d "$INSTALL_DIR/skills" ] && ln -sf "$INSTALL_DIR/skills" "$HOME/.claude/skills"
    [ -d "$INSTALL_DIR/agents" ] && ln -sf "$INSTALL_DIR/agents" "$HOME/.claude/agents"

    log_info "Claude Code integration complete"
}

print_success() {
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}   CODITECT INSTALLED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    echo "Install location: $INSTALL_DIR"
    echo "User symlink:     $USER_LINK"
    echo "Auto-updates:     Daily at 9:00 AM"
    echo ""
    echo "Next steps:"
    echo "  1. Restart terminal or: source ~/.zshrc"
    echo "  2. In any project: ln -s ~/.coditect .coditect"
    echo ""
    echo "Manual update: /opt/coditect/update.sh"
    echo ""
}

main() {
    print_banner
    check_dependencies
    install_coditect
    create_user_symlink
    setup_path
    setup_auto_updater
    setup_claude_integration
    print_success
}

main "$@"

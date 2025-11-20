#!/bin/bash
#
# CODITECT Licensed Installer
# Usage: curl -fsSL https://az1.ai/install | bash
#
# Requires valid license key from https://az1.ai/coditect
# 14-day trial with money-back guarantee
#
set -e

# Configuration
CODITECT_API="${CODITECT_API:-https://api.az1.ai/api/v1}"
CODITECT_REPO="${CODITECT_REPO:-https://github.com/coditect-ai/coditect-ops-distribution.git}"
CODITECT_BRANCH="${CODITECT_BRANCH:-main}"
INSTALL_DIR="/opt/coditect"
USER_LINK="$HOME/.coditect"
LICENSE_FILE="$HOME/.coditect-license"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.coditect.updater.plist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${BLUE}┌───────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  CODITECT Installer v1.0                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  AI-Powered Development Framework         ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                           ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  © 2025 AZ1.AI INC. All Rights Reserved   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  LICENSED | 2025-11-19-v6.1 | 1@az1.ai    ${BLUE}│${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────┘${NC}"
    echo ""
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

get_license_key() {
    # Check if license key provided as argument or environment variable
    if [ -n "$CODITECT_LICENSE" ]; then
        LICENSE_KEY="$CODITECT_LICENSE"
        return
    fi

    # Check for existing license file
    if [ -f "$LICENSE_FILE" ]; then
        LICENSE_KEY=$(cat "$LICENSE_FILE")
        log_info "Using saved license key"
        return
    fi

    # Prompt for license key
    echo ""
    echo -e "${YELLOW}License key required${NC}"
    echo "Get your license at: https://az1.ai/coditect"
    echo "14-day trial with money-back guarantee"
    echo ""
    read -p "Enter license key: " LICENSE_KEY

    if [ -z "$LICENSE_KEY" ]; then
        log_error "License key is required"
        exit 1
    fi
}

validate_license() {
    log_info "Validating license..."

    # Call license validation API
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST "${CODITECT_API}/licenses/validate" \
        -H "Content-Type: application/json" \
        -d "{\"license_key\": \"${LICENSE_KEY}\", \"action\": \"install\", \"machine_id\": \"$(hostname)\"}" \
        2>/dev/null)

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
        # Save license key for future use
        echo "$LICENSE_KEY" > "$LICENSE_FILE"
        chmod 600 "$LICENSE_FILE"

        # Extract license info
        LICENSE_STATUS=$(echo "$BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        DAYS_LEFT=$(echo "$BODY" | grep -o '"days_remaining":[0-9]*' | cut -d':' -f2)

        if [ "$LICENSE_STATUS" = "trial" ]; then
            log_info "License valid - Trial: ${DAYS_LEFT} days remaining"
        else
            log_info "License valid - Active subscription"
        fi
    elif [ "$HTTP_CODE" = "402" ]; then
        log_error "License expired. Please renew at https://az1.ai/account"
        exit 1
    elif [ "$HTTP_CODE" = "401" ]; then
        log_error "Invalid license key"
        exit 1
    else
        log_warn "Could not validate license (offline mode)"
        # Allow installation in offline mode if license file exists
        if [ ! -f "$LICENSE_FILE" ]; then
            log_error "License validation failed. Check your internet connection."
            exit 1
        fi
    fi
}

phone_home() {
    # Send telemetry (non-blocking)
    curl -s -X POST "${CODITECT_API}/telemetry" \
        -H "Content-Type: application/json" \
        -d "{\"license_key\": \"${LICENSE_KEY}\", \"event\": \"$1\", \"version\": \"2025-11-19-v6.1\", \"os\": \"$(uname -s)\", \"machine_id\": \"$(hostname)\"}" \
        >/dev/null 2>&1 &
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v git &> /dev/null; then
        log_error "git is required but not installed."
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed."
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
        # Add both bin (commands) and scripts (utilities) to PATH
        PATH_EXPORT='export PATH="$HOME/.coditect/bin:$HOME/.coditect/scripts:$PATH"'

        if ! grep -q "coditect/bin" "$SHELL_CONFIG" 2>/dev/null; then
            # Remove old coditect PATH entries
            grep -v "coditect" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp" 2>/dev/null && mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG" || true
            echo "" >> "$SHELL_CONFIG"
            echo "# CODITECT" >> "$SHELL_CONFIG"
            echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
            log_info "Added CODITECT to PATH in $SHELL_CONFIG"
        else
            log_info "PATH already configured"
        fi
    else
        log_warn "Could not find shell config. Add to your shell config:"
        echo "  export PATH=\"\$HOME/.coditect/bin:\$HOME/.coditect/scripts:\$PATH\""
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
        <string>--quiet</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>/tmp/coditect-updater.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/coditect-updater.log</string>
</dict>
</plist>
PLIST

    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    launchctl load "$LAUNCHD_PLIST"

    log_info "Auto-updater configured (hourly checks)"
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
    echo "Auto-updates:     Hourly (silent)"
    echo ""
    echo "Commands available after restart:"
    echo "  coditect-update    Update to latest version"
    echo "  coditect-check     Check for updates"
    echo "  coditect-version   Show version info"
    echo ""
    echo "Next steps:"
    echo "  1. Restart terminal or: source ~/.zshrc"
    echo "  2. In any project: ln -s ~/.coditect .coditect"
    echo ""
}

main() {
    print_banner
    check_dependencies
    get_license_key
    validate_license
    phone_home "install_start"
    install_coditect
    create_user_symlink
    setup_path
    setup_auto_updater
    setup_claude_integration
    phone_home "install_complete"
    print_success
}

main "$@"

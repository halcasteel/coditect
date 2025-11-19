#!/bin/bash
#
# CODITECT Updater
# Usage: update.sh [--check|--force|--quiet]
#
set -e

INSTALL_DIR="/opt/coditect"
CODITECT_BRANCH="${CODITECT_BRANCH:-main}"
CODITECT_API="${CODITECT_API:-https://api.az1.ai/api/v1}"
LICENSE_FILE="$HOME/.coditect-license"
LOG_FILE="/tmp/coditect-updater.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
CHECK_ONLY=false
FORCE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --check|-c) CHECK_ONLY=true; shift ;;
        --force|-f) FORCE=true; shift ;;
        --quiet|-q) QUIET=true; shift ;;
        --help|-h)
            echo "CODITECT Updater"
            echo ""
            echo "Usage: update.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check, -c    Check for updates without installing"
            echo "  --force, -f    Force update even if up-to-date"
            echo "  --quiet, -q    Suppress output (for cron/launchd)"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *) shift ;;
    esac
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    if [ "$QUIET" = false ]; then
        echo -e "$1"
    fi
}

# Print banner (only in interactive mode)
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${BLUE}┌───────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  CODITECT Updater                         ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  AI-Powered Development Framework         ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                           ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  © 2025 AZ1.AI INC. All Rights Reserved   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  LICENSED | 2025-11-19-v6.1 | 1@az1.ai    ${BLUE}│${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────┘${NC}"
    echo ""
fi

# Check if installation exists
if [ ! -d "$INSTALL_DIR/.git" ]; then
    log "${RED}ERROR: CODITECT not installed at $INSTALL_DIR${NC}"
    exit 1
fi

# Validate license (skip in quiet mode if already validated today)
if [ -f "$LICENSE_FILE" ]; then
    LICENSE_KEY=$(cat "$LICENSE_FILE")

    # Check license with API
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "${CODITECT_API}/licenses/validate" \
        -H "Content-Type: application/json" \
        -d "{\"license_key\": \"${LICENSE_KEY}\", \"action\": \"update\"}" \
        2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "402" ]; then
        log "${RED}License expired. Please renew at https://az1.ai/account${NC}"
        if command -v osascript &> /dev/null; then
            osascript -e 'display notification "License expired. Please renew." with title "CODITECT"' 2>/dev/null || true
        fi
        exit 1
    elif [ "$HTTP_CODE" = "401" ]; then
        log "${RED}Invalid license. Please reinstall with valid license.${NC}"
        exit 1
    fi
else
    log "${RED}No license found. Please reinstall CODITECT.${NC}"
    exit 1
fi

# Check for updates
cd "$INSTALL_DIR"

log "Checking for updates..."

# Fetch latest
sudo git fetch origin "$CODITECT_BRANCH" --quiet

# Get current and latest commits
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$CODITECT_BRANCH")
LOCAL_SHORT=$(git rev-parse --short HEAD)
REMOTE_SHORT=$(git rev-parse --short "origin/$CODITECT_BRANCH")

if [ "$LOCAL" = "$REMOTE" ] && [ "$FORCE" = false ]; then
    if [ "$QUIET" = false ]; then
        log "${GREEN}Already up-to-date${NC} (${LOCAL_SHORT})"
    fi
    exit 0
fi

# If we get here, there's an update available

# Get commit info
COMMITS_BEHIND=$(git rev-list --count HEAD..origin/$CODITECT_BRANCH)
LATEST_MSG=$(git log -1 --format="%s" origin/$CODITECT_BRANCH)

# In quiet mode (background checks), just notify - don't auto-install
if [ "$QUIET" = true ]; then
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"${COMMITS_BEHIND} update(s) available. Run: coditect-update\" with title \"CODITECT Update Available\"" 2>/dev/null || true
    fi
    exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
    log "${YELLOW}Update available!${NC}"
    log "  Current: ${LOCAL_SHORT}"
    log "  Latest:  ${REMOTE_SHORT} (${COMMITS_BEHIND} commits behind)"
    log "  Message: ${LATEST_MSG}"
    log ""
    log "Run 'coditect-update' to install update"
    exit 0
fi

# Update available - install it
log "${BLUE}Installing update...${NC}"
log "  ${LOCAL_SHORT} -> ${REMOTE_SHORT} (${COMMITS_BEHIND} commits)"

# Pull updates
sudo git reset --hard "origin/$CODITECT_BRANCH"
sudo git submodule update --init --recursive

# Reset permissions
sudo chown -R root:staff "$INSTALL_DIR" 2>/dev/null || true
sudo chmod -R 755 "$INSTALL_DIR"
sudo find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
sudo find "$INSTALL_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod 755 {} \;

log "${GREEN}Updated successfully!${NC}"
log "  Version: $(git rev-parse --short HEAD)"
log "  Message: ${LATEST_MSG}"

# Always send notification when updated (even in quiet mode)
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"Updated to ${REMOTE_SHORT}: ${LATEST_MSG}\" with title \"CODITECT Updated\"" 2>/dev/null || true
fi

exit 0

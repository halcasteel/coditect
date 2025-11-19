#!/bin/bash
#
# CODITECT Auto-Updater
# Runs daily via launchd to keep CODITECT up-to-date
#
set -e

INSTALL_DIR="/opt/coditect"
CODITECT_BRANCH="${CODITECT_BRANCH:-main}"
LOG_FILE="/tmp/coditect-updater.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if installation exists
if [ ! -d "$INSTALL_DIR/.git" ]; then
    log "ERROR: CODITECT not installed at $INSTALL_DIR"
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

if [ "$LOCAL" = "$REMOTE" ]; then
    log "Already up-to-date"
    exit 0
fi

# Update available
log "Update available: $LOCAL -> $REMOTE"

# Pull updates
sudo git reset --hard "origin/$CODITECT_BRANCH"
sudo git submodule update --init --recursive

# Reset permissions
sudo chown -R root:staff "$INSTALL_DIR" 2>/dev/null || true
sudo chmod -R 755 "$INSTALL_DIR"
sudo find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
sudo find "$INSTALL_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod 755 {} \;

log "Updated successfully to $(git rev-parse --short HEAD)"

# Optional: Send notification (macOS)
if command -v osascript &> /dev/null; then
    osascript -e 'display notification "CODITECT has been updated to the latest version" with title "CODITECT Update"' 2>/dev/null || true
fi

exit 0

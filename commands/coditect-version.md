# CODITECT Version

Show current CODITECT version information.

## Automatic Execution

Run this command to show version info:

```bash
if [ -d "/opt/coditect/.git" ]; then
    cd /opt/coditect
    echo "CODITECT $(git rev-parse --short HEAD)"
    echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "Updated: $(git log -1 --format='%ci')"
    echo "Message: $(git log -1 --format='%s')"
else
    echo "CODITECT not installed"
fi
```

## Usage

Just run `/coditect-version` - no arguments needed.

# CODITECT Installer - Workflow Diagrams

This directory contains Mermaid diagrams documenting the CODITECT Installer workflows and architecture.

## Diagrams

### 1. installer-flow.mmd
**High-Level Installation Flow**

Shows the complete user journey from launching the installer to completion, including all entry points (launch.py, install_gui.py, install.py, install.sh) and decision points.

**Key Features:**
- Auto-detection logic for GUI availability
- Platform-specific handling
- Error paths and recovery
- User experience flow

**View:** [installer-flow.mmd](installer-flow.mmd)

### 2. cli-flow.mmd
**CLI Installer Detailed Flow**

Detailed workflow for the command-line installer (install.py), showing all command-line arguments, validation logic, and step-by-step installation process.

**Key Features:**
- Argument parsing (--venv-only, --deps-only, --help)
- Platform detection and configuration
- Virtual environment management
- Dependency installation with pip
- Error handling and recovery instructions

**View:** [cli-flow.mmd](cli-flow.mmd)

### 3. gui-flow.mmd
**GUI Installer Detailed Flow**

Detailed workflow for the graphical installer (install_gui.py), including UI component structure, threading model, and message queue communication.

**Key Features:**
- UI component initialization
- Background thread for installation
- Message queue for thread communication
- Real-time progress updates
- Success and error dialog handling

**View:** [gui-flow.mmd](gui-flow.mmd)

### 4. platform-detection.mmd
**Platform Detection and Path Resolution**

Shows how the installer detects the operating system and resolves platform-specific paths for Python executables, venv activation scripts, and file paths.

**Key Features:**
- Platform detection using `platform.system()`
- Windows vs Unix path differences
- Helper method abstractions
- ANSI color handling

**View:** [platform-detection.mmd](platform-detection.mmd)

## Viewing Diagrams

### Online (GitHub)
GitHub automatically renders Mermaid diagrams. Just open any `.mmd` file on GitHub.

### Local (VS Code)
Install the "Markdown Preview Mermaid Support" extension:
```bash
code --install-extension bierner.markdown-mermaid
```

Then open any `.mmd` file and use "Markdown: Open Preview" (Ctrl+Shift+V / Cmd+Shift+V).

### Command Line (mermaid-cli)
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate SVG
mmdc -i installer-flow.mmd -o installer-flow.svg

# Generate PNG
mmdc -i installer-flow.mmd -o installer-flow.png
```

### Online Editor
Paste diagram content into: https://mermaid.live

## Diagram Syntax

All diagrams use Mermaid syntax:
- **Graph TD:** Top-down flowchart
- **Subgraphs:** Logical grouping of steps
- **Styles:** Color-coded nodes (success=green, error=red, warning=yellow)
- **Decisions:** Diamond shapes with Yes/No branches

## Color Coding

- 🔵 **Blue (#2563eb):** Start points, user actions
- 🟢 **Green (#10b981):** Success states, completion
- 🔴 **Red (#ef4444):** Error states, failures
- 🟡 **Yellow (#fbbf24):** Warnings, optional steps

## Updating Diagrams

When updating installer code, remember to update relevant diagrams:

1. **Add new feature** → Update installer-flow.mmd
2. **Change CLI logic** → Update cli-flow.mmd
3. **Modify GUI** → Update gui-flow.mmd
4. **Platform handling** → Update platform-detection.mmd

## Exporting to Documentation

To include diagrams in other documentation:

**Markdown:**
```markdown
![Installer Flow](diagrams/installer-flow.svg)
```

**HTML:**
```html
<img src="diagrams/installer-flow.svg" alt="Installer Flow" />
```

**reStructuredText:**
```rst
.. image:: diagrams/installer-flow.svg
   :alt: Installer Flow
```

---

**Last Updated:** November 16, 2025
**Maintainer:** AZ1.AI CODITECT Team

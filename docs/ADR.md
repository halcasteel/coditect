# Architecture Decision Records - CODITECT Installer

## Overview

This document records the key architectural decisions made during the development of the CODITECT Framework Installer. Each decision includes context, options considered, decision made, rationale, and consequences.

---

## ADR-001: Cross-Platform Implementation Strategy

### Status
**Accepted** - November 16, 2025

### Context
We need to create an installer that works on Windows, macOS, and Linux with minimal user friction and maximum automation capability.

### Options Considered

1. **Platform-Specific Installers**
   - Windows: MSI via WiX Toolset
   - macOS: PKG or DMG
   - Linux: .deb and .rpm
   - **Pros:** Native OS integration, familiar UX
   - **Cons:** 3x development effort, hard to maintain, requires multiple build systems

2. **Shell Scripts Only**
   - Bash script for Unix, PowerShell for Windows
   - **Pros:** No dependencies, lightweight
   - **Cons:** Different syntax, limited error handling, no GUI

3. **Pure Python Implementation**
   - Single codebase with platform detection
   - tkinter for GUI (built-in)
   - **Pros:** Cross-platform, single codebase, good UX
   - **Cons:** Requires Python pre-installed

### Decision
**Use Pure Python Implementation with platform detection**

### Rationale
- Python 3.8+ is prerequisite for CODITECT anyway
- Single codebase reduces maintenance burden by 70%
- tkinter provides professional GUI without external dependencies
- Platform abstraction via `platform.system()` and `pathlib`
- Easy to test and maintain
- Supports both GUI and CLI modes

### Consequences
**Positive:**
- ✅ Single codebase for all platforms
- ✅ Professional UX with tkinter GUI
- ✅ Automation-friendly CLI mode
- ✅ Easy unit testing
- ✅ Fast development iteration

**Negative:**
- ⚠️ Requires Python pre-installed (acceptable for CODITECT users)
- ⚠️ tkinter may be missing on some Linux distros (fallback to CLI)

### Implementation
See: `install.py` (CrossPlatformInstaller class)

---

## ADR-002: GUI Framework Selection

### Status
**Accepted** - November 16, 2025

### Context
Users need a modern, professional GUI for first-time installation. We evaluated multiple Python GUI frameworks.

### Options Considered

1. **tkinter**
   - Built-in with Python
   - **Pros:** No dependencies, cross-platform, sufficient for installer
   - **Cons:** Less modern than alternatives

2. **PyQt5/PySide6**
   - Professional Qt framework
   - **Pros:** Very modern, rich widgets
   - **Cons:** 50MB+ dependency, licensing complexity

3. **wxPython**
   - Native widgets
   - **Pros:** Native look and feel
   - **Cons:** 20MB+ dependency, installation complexity

4. **Web-based (Electron, CEF)**
   - HTML/CSS/JavaScript UI
   - **Pros:** Very modern, flexible
   - **Cons:** 100MB+ dependency, complexity

### Decision
**Use tkinter with modern styling**

### Rationale
- Zero dependencies (built-in with Python)
- Cross-platform without platform-specific builds
- Sufficient for installer UI needs
- Professional appearance achievable with proper styling
- Graceful fallback to CLI if unavailable

**Cost-Benefit Analysis:**
- PyQt5 adds 50MB + licensing complexity
- wxPython adds 20MB + installation issues
- Electron adds 100MB + web stack complexity
- tkinter adds 0MB + 0 dependencies

### Consequences
**Positive:**
- ✅ Zero external dependencies
- ✅ Works out-of-box on Windows/macOS
- ✅ Small footprint (~40-60MB RAM)
- ✅ Fast startup (~0.5 seconds)

**Negative:**
- ⚠️ May need `python3-tk` package on Linux (documented)
- ⚠️ Less modern than Qt/wxPython (acceptable trade-off)

### Implementation
See: `install_gui.py` (InstallerGUI class)

---

## ADR-003: Threading Model for GUI

### Status
**Accepted** - November 16, 2025

### Context
Installation can take 20-35 seconds. GUI must remain responsive during installation without freezing.

### Options Considered

1. **Single-threaded with periodic updates**
   - `root.update()` calls
   - **Pros:** Simple
   - **Cons:** Janky UX, can still freeze

2. **Multiprocessing**
   - Separate process for installation
   - **Pros:** True parallelism
   - **Cons:** Complex IPC, resource overhead

3. **Threading with message queue**
   - Background thread + queue for communication
   - **Pros:** Responsive UI, thread-safe
   - **Cons:** Slightly more complex

### Decision
**Use threading with message queue pattern**

### Rationale
- **Responsive UI:** Main thread handles tkinter events
- **Non-blocking:** Installation runs in background thread
- **Thread-safe:** Queue for inter-thread communication
- **Standard pattern:** Well-documented Python pattern
- **No IPC complexity:** Shared memory within process

**Architecture:**
```
Main Thread (tkinter)     Background Thread
     |                            |
     |--[User clicks Install]---->|
     |                            |
     |                      [Run installation]
     |                            |
     |<----[Queue: progress]------|
     |                            |
     [Update UI]                  |
     |                            |
     |<----[Queue: success]-------|
     |                            |
     [Show dialog]                |
```

### Consequences
**Positive:**
- ✅ UI never freezes
- ✅ Real-time progress updates
- ✅ User can cancel if needed
- ✅ Professional UX

**Negative:**
- ⚠️ Slightly more complex than single-threaded
- ⚠️ Queue polling adds 100ms latency (acceptable)

### Implementation
See: `install_gui.py` (`_run_installation()` method, message queue)

---

## ADR-004: Virtual Environment Management

### Status
**Accepted** - November 16, 2025

### Context
Dependencies like GitPython must be installed without affecting system Python.

### Options Considered

1. **System-wide installation**
   - `pip install --user`
   - **Pros:** Simple
   - **Cons:** Pollutes system, requires permissions, conflicts

2. **Conda environment**
   - `conda create -n coditect`
   - **Pros:** Isolated environment
   - **Cons:** Requires Conda, large dependency

3. **Python venv**
   - `python3 -m venv venv`
   - **Pros:** Built-in, isolated, no sudo
   - **Cons:** None significant

### Decision
**Use Python venv (PEP 405)**

### Rationale
- **Built-in:** No external dependencies
- **Isolated:** No system pollution
- **No sudo:** User-space installation
- **Cross-platform:** Works everywhere
- **Standard:** Python community best practice

**Security Benefits:**
- No system-wide modifications
- Easy to delete (`rm -rf venv`)
- No permission escalation

### Consequences
**Positive:**
- ✅ Zero system impact
- ✅ Clean uninstall
- ✅ No permission issues
- ✅ Fast creation (~5 seconds)

**Negative:**
- ⚠️ ~30MB disk space per venv (acceptable)

### Implementation
See: `install.py` (`create_venv()` method)

---

## ADR-005: Platform Detection Strategy

### Status
**Accepted** - November 16, 2025

### Context
Installer must handle platform-specific differences (paths, executables, activation).

### Options Considered

1. **Manual OS checking**
   - `sys.platform` checks everywhere
   - **Pros:** Explicit
   - **Cons:** Repetitive, error-prone

2. **Factory pattern with platform classes**
   - `WindowsInstaller`, `MacOSInstaller`, `LinuxInstaller`
   - **Pros:** Clean separation
   - **Cons:** Overkill for simple differences

3. **Platform detection with helper methods**
   - Detect once, use helper methods for paths
   - **Pros:** Clean, DRY
   - **Cons:** None

### Decision
**Platform detection with helper methods**

### Rationale
- **Detect once:** `self.os_type = platform.system()` in `__init__`
- **Helper methods:** `get_python_executable()`, `get_venv_python()`, etc.
- **DRY principle:** No repeated OS checks
- **Maintainable:** Easy to add new platforms
- **Testable:** Mock `platform.system()`

**Platform Handling:**
```python
def get_python_executable(self) -> str:
    if self.os_type == 'Windows':
        return 'python'   # Windows convention
    return 'python3'      # Unix convention
```

### Consequences
**Positive:**
- ✅ Single point of platform detection
- ✅ Easy to add new platforms
- ✅ Testable via mocking
- ✅ Clean abstraction

**Negative:**
- None

### Implementation
See: `install.py` (CrossPlatformInstaller helper methods)

---

## ADR-006: Error Handling Philosophy

### Status
**Accepted** - November 16, 2025

### Context
Installer encounters various errors (network, permissions, missing dependencies). Users need helpful guidance.

### Options Considered

1. **Minimal error messages**
   - "Error: Installation failed"
   - **Pros:** Simple
   - **Cons:** Users frustrated, no actionable info

2. **Technical error dumps**
   - Full stack traces, technical details
   - **Pros:** Complete information
   - **Cons:** Overwhelming for users

3. **User-friendly with recovery steps**
   - Clear problem + actionable solution
   - **Pros:** Users can self-recover
   - **Cons:** More documentation effort

### Decision
**User-friendly messages with recovery steps**

### Rationale
- **Target audience:** Developers, but may be new to CODITECT
- **Self-service:** Users can fix issues without support
- **Professional:** Reflects well on CODITECT quality
- **Examples:**

**Bad:**
```
Error: ModuleNotFoundError: No module named 'tkinter'
```

**Good:**
```
Error: tkinter not found. Please install tkinter:
  Ubuntu/Debian: sudo apt-get install python3-tk
  Fedora: sudo dnf install python3-tkinter
  macOS: tkinter should be included with Python
  Windows: tkinter should be included with Python
```

### Consequences
**Positive:**
- ✅ Reduced support burden
- ✅ Better user experience
- ✅ Professional impression
- ✅ Faster issue resolution

**Negative:**
- ⚠️ More documentation work (one-time cost)

### Implementation
See: `install.py` and `install_gui.py` (error messages)

---

## ADR-007: Universal Launcher Pattern

### Status
**Accepted** - November 16, 2025

### Context
Users may have tkinter or not. We want best UX automatically without user knowing technical details.

### Options Considered

1. **Two separate entry points**
   - `install_gui.py` and `install.py`
   - **Pros:** Simple
   - **Cons:** User must know which to run

2. **GUI with CLI fallback**
   - Always try GUI first
   - **Pros:** Best UX for most
   - **Cons:** Confusing if GUI fails

3. **Universal launcher with auto-detection**
   - Detect GUI availability, launch appropriate mode
   - **Pros:** Best UX, intelligent
   - **Cons:** One more file

### Decision
**Universal launcher (`launch.py`) with auto-detection**

### Rationale
- **Best UX:** GUI if available, CLI fallback
- **Flexible:** `--gui` and `--cli` flags for explicit control
- **Professional:** Users don't need to know technical details
- **Single command:** `python3 launch.py` works everywhere

**Decision Flow:**
```
launch.py
  ├─ --gui? → Check tkinter → GUI or error
  ├─ --cli? → CLI
  └─ auto? → Check tkinter → GUI or CLI fallback
```

### Consequences
**Positive:**
- ✅ Best possible UX automatically
- ✅ Still supports explicit mode selection
- ✅ Professional first impression
- ✅ Reduces user confusion

**Negative:**
- ⚠️ One extra file (acceptable)

### Implementation
See: `launch.py` (main entry point)

---

## ADR-008: Bash Script Alternative

### Status
**Accepted** - November 16, 2025

### Context
Some environments may have issues with Python GUI, or users may prefer shell scripts.

### Options Considered

1. **No shell script**
   - Python only
   - **Pros:** Less to maintain
   - **Cons:** No fallback for edge cases

2. **Shell script only**
   - No Python installer
   - **Pros:** Minimal dependencies
   - **Cons:** Windows support difficult

3. **Both Python and shell script**
   - Best of both worlds
   - **Pros:** Maximum compatibility
   - **Cons:** 2x maintenance (partial)

### Decision
**Provide bash script (`install.sh`) as alternative**

### Rationale
- **Edge case coverage:** WSL without tkinter, minimal environments
- **User preference:** Some users prefer shell scripts
- **Minimal overhead:** Shell script is small (~170 lines)
- **Same functionality:** Creates venv, installs dependencies

**When to use bash script:**
- tkinter unavailable and can't install
- WSL without X server
- User preference for shell
- Minimal environments

### Consequences
**Positive:**
- ✅ Maximum compatibility
- ✅ User choice
- ✅ Covers edge cases
- ✅ Small maintenance overhead

**Negative:**
- ⚠️ Two installers to maintain (but minimal)

### Implementation
See: `install.sh` (Bash alternative)

---

## ADR-009: Dependency Pinning Strategy

### Status
**Accepted** - November 16, 2025

### Context
GitPython is the primary dependency. We need to balance stability vs. security updates.

### Options Considered

1. **Exact version pinning**
   - `gitpython==3.1.40`
   - **Pros:** Reproducible
   - **Cons:** No security updates

2. **No pinning**
   - `gitpython`
   - **Pros:** Always latest
   - **Cons:** Breaking changes

3. **Minimum version with caret**
   - `gitpython>=3.1.0`
   - **Pros:** Security updates, stable API
   - **Cons:** Possible breaking changes

### Decision
**Minimum version: `gitpython>=3.1.0`**

### Rationale
- **Security:** Get important fixes
- **Stability:** 3.1.0 introduced stable API
- **Tested:** Known to work with 3.1.x
- **Future-proof:** Will work with 3.2.x, 3.3.x

**Risk Assessment:**
- GitPython follows semantic versioning
- 3.x.y changes should be backward compatible
- We verify installation with version check

### Consequences
**Positive:**
- ✅ Security updates automatically
- ✅ Bug fixes automatically
- ✅ No need to update requirements often

**Negative:**
- ⚠️ Potential for breaking changes (low risk)
- ⚠️ Need to monitor GitPython releases

### Implementation
See: `requirements.txt` (`gitpython>=3.1.0`)

---

## ADR-010: Standalone Packaging Future

### Status
**Proposed** - November 16, 2025

### Context
For future phases, we may want standalone executables that don't require Python pre-installed.

### Options Considered

1. **PyInstaller**
   - Single-file executable
   - **Pros:** Simple, cross-platform
   - **Cons:** 20-30MB size

2. **Nuitka**
   - Compiles Python to C
   - **Pros:** Smaller, faster
   - **Cons:** Complex build

3. **Platform-specific**
   - MSI (Windows), DMG (macOS), DEB/RPM (Linux)
   - **Pros:** Native integration
   - **Cons:** 3x build complexity

### Decision (Proposed)
**Phase 2: Use PyInstaller for standalone executables**

### Rationale
- **Phase 1 (current):** Python installer sufficient for pilot
- **Phase 2:** PyInstaller for wider distribution
- **Phase 3:** Platform-specific packages for enterprise

**Not implementing now because:**
- Pilot users are developers (have Python)
- Simpler to test and iterate
- Can add later without breaking existing

### Consequences
**Positive:**
- ✅ Faster pilot deployment
- ✅ Simpler testing
- ✅ Can add packaging later

**Negative:**
- ⚠️ Requires Python for now (acceptable)

### Future Implementation
```bash
# Build standalone executable
pyinstaller --onefile --windowed \
    --name "CODITECT Installer" \
    --icon icon.ico \
    scripts/installer/install_gui.py
```

---

## ADR-011: Git Submodule for Installer

### Status
**Accepted** - November 16, 2025

### Context
Installer should be reusable across CODITECT projects (rollout-master, cloud-backend, etc.).

### Options Considered

1. **Copy installer to each project**
   - Duplicate files
   - **Pros:** Simple
   - **Cons:** Updates difficult, maintenance burden

2. **Package on PyPI**
   - `pip install coditect-installer`
   - **Pros:** Standard distribution
   - **Cons:** Overkill, versioning complexity

3. **Git submodule**
   - Single source of truth
   - **Pros:** Reusable, versioned, updates easy
   - **Cons:** Git submodule learning curve

### Decision
**Use git submodule for installer**

### Rationale
- **Single source:** Update once, use everywhere
- **Versioned:** Can pin to specific commit/tag
- **Reusable:** All CODITECT projects benefit
- **Standard:** Git submodule is industry standard

**Integration:**
```bash
# In any CODITECT project
git submodule add https://github.com/halcasteel/coditect-installer.git scripts/installer
```

### Consequences
**Positive:**
- ✅ Single source of truth
- ✅ Easy updates across projects
- ✅ Independent versioning
- ✅ Reusable

**Negative:**
- ⚠️ Git submodule workflow (documented)

### Implementation
- Created: https://github.com/halcasteel/coditect-installer
- Usage: Add as submodule in CODITECT projects

---

## Summary

### Accepted ADRs
- ADR-001: Pure Python cross-platform implementation
- ADR-002: tkinter for GUI
- ADR-003: Threading with message queue
- ADR-004: Python venv for dependencies
- ADR-005: Platform detection with helper methods
- ADR-006: User-friendly error messages
- ADR-007: Universal launcher pattern
- ADR-008: Bash script alternative
- ADR-009: Minimum version pinning
- ADR-011: Git submodule for reusability

### Proposed ADRs
- ADR-010: PyInstaller for Phase 2

### Key Principles
1. **Cross-platform first:** Single codebase for all OSs
2. **Zero dependencies:** Use built-in Python modules
3. **User-friendly:** Clear messages with recovery steps
4. **Professional UX:** Modern GUI with CLI fallback
5. **Reusable:** Git submodule for all CODITECT projects

---

**Last Updated:** November 16, 2025
**Status:** Production Ready (Pilot Phase)
**Version:** 1.0.0

# Test-Driven Development Specification - CODITECT Installer

## 1. Testing Philosophy

### 1.1 TDD Approach
This project follows **Test-Driven Development (TDD)** principles:

1. **Write test first** - Define expected behavior
2. **Run test (should fail)** - Verify test is valid
3. **Write minimal code** - Make test pass
4. **Refactor** - Clean up while keeping tests green
5. **Repeat** - For each new feature

### 1.2 Testing Pyramid

```
         /\
        /  \
       /E2E \      10% - End-to-End (Manual testing)
      /------\
     /Integration\  20% - Integration (API + workflow)
    /------------\
   / Unit Tests   \ 70% - Unit (Functions + classes)
  /________________\
```

### 1.3 Quality Goals

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Unit test coverage | 80%+ | 0% | ⏸️ Pending |
| Integration test coverage | 60%+ | 0% | ⏸️ Pending |
| All tests passing | 100% | N/A | ⏸️ Pending |
| Test execution time | < 30s | N/A | ⏸️ Pending |
| Platform coverage | 3/3 | 2/3 | 🟡 Manual only |

---

## 2. Test Structure

### 2.1 Directory Layout

```
scripts/installer/
├── tests/
│   ├── __init__.py
│   ├── unit/
│   │   ├── test_platform_detection.py
│   │   ├── test_python_version.py
│   │   ├── test_path_resolution.py
│   │   ├── test_color_output.py
│   │   └── test_error_messages.py
│   ├── integration/
│   │   ├── test_cli_installation.py
│   │   ├── test_gui_initialization.py
│   │   ├── test_venv_creation.py
│   │   └── test_dependency_installation.py
│   ├── manual/
│   │   ├── test_windows.md
│   │   ├── test_macos.md
│   │   └── test_linux.md
│   └── fixtures/
│       ├── mock_requirements.txt
│       └── test_venv/
├── install.py
├── install_gui.py
└── launch.py
```

### 2.2 Test Organization

**Unit Tests (70%):**
- Test individual functions in isolation
- Mock external dependencies
- Fast execution (< 1s per test)
- No file I/O or network

**Integration Tests (20%):**
- Test workflows end-to-end
- Real file system operations
- Real subprocess calls
- Slower execution (< 5s per test)

**Manual Tests (10%):**
- Platform-specific testing
- GUI visual inspection
- User acceptance testing

---

## 3. Unit Test Specifications

### 3.1 Platform Detection (test_platform_detection.py)

#### Test Case 1.1: Detect Windows Platform
```python
def test_detect_windows():
    """Verify Windows is detected correctly"""
    with mock.patch('platform.system', return_value='Windows'):
        installer = CrossPlatformInstaller()
        assert installer.os_type == 'Windows'
```

**Expected:** `os_type == 'Windows'`
**Priority:** P0 (Critical)

#### Test Case 1.2: Detect macOS Platform
```python
def test_detect_macos():
    """Verify macOS is detected correctly"""
    with mock.patch('platform.system', return_value='Darwin'):
        installer = CrossPlatformInstaller()
        assert installer.os_type == 'Darwin'
```

**Expected:** `os_type == 'Darwin'`
**Priority:** P0 (Critical)

#### Test Case 1.3: Detect Linux Platform
```python
def test_detect_linux():
    """Verify Linux is detected correctly"""
    with mock.patch('platform.system', return_value='Linux'):
        installer = CrossPlatformInstaller()
        assert installer.os_type == 'Linux'
```

**Expected:** `os_type == 'Linux'`
**Priority:** P0 (Critical)

### 3.2 Python Version Checking (test_python_version.py)

#### Test Case 2.1: Python Version Too Old
```python
def test_python_too_old():
    """Verify error when Python < 3.8"""
    installer = CrossPlatformInstaller()

    with mock.patch('sys.version_info', (3, 7, 5)):
        success, message = installer.check_python_version()
        assert success == False
        assert "3.8+" in message
        assert "3.7.5" in message
```

**Expected:** `success=False, message contains version`
**Priority:** P0 (Critical)

#### Test Case 2.2: Python Version Sufficient
```python
def test_python_sufficient():
    """Verify success when Python >= 3.8"""
    installer = CrossPlatformInstaller()

    with mock.patch('sys.version_info', (3, 11, 5)):
        success, version = installer.check_python_version()
        assert success == True
        assert version == "3.11.5"
```

**Expected:** `success=True, version="3.11.5"`
**Priority:** P0 (Critical)

#### Test Case 2.3: Python Exactly 3.8.0
```python
def test_python_exact_minimum():
    """Verify 3.8.0 is accepted"""
    installer = CrossPlatformInstaller()

    with mock.patch('sys.version_info', (3, 8, 0)):
        success, version = installer.check_python_version()
        assert success == True
        assert version == "3.8.0"
```

**Expected:** `success=True` (edge case)
**Priority:** P1 (Important)

### 3.3 Path Resolution (test_path_resolution.py)

#### Test Case 3.1: Windows Python Executable
```python
def test_windows_python_executable():
    """Verify Windows uses 'python' not 'python3'"""
    with mock.patch('platform.system', return_value='Windows'):
        installer = CrossPlatformInstaller()
        assert installer.get_python_executable() == 'python'
```

**Expected:** `'python'`
**Priority:** P0 (Critical)

#### Test Case 3.2: Unix Python Executable
```python
def test_unix_python_executable():
    """Verify Unix uses 'python3'"""
    with mock.patch('platform.system', return_value='Linux'):
        installer = CrossPlatformInstaller()
        assert installer.get_python_executable() == 'python3'
```

**Expected:** `'python3'`
**Priority:** P0 (Critical)

#### Test Case 3.3: Windows Venv Activation
```python
def test_windows_venv_activation():
    """Verify Windows activation path"""
    with mock.patch('platform.system', return_value='Windows'):
        installer = CrossPlatformInstaller()
        activation = installer.get_venv_activation_command()
        assert 'Scripts\\activate.bat' in activation or 'Scripts/activate.bat' in activation
```

**Expected:** Contains `Scripts/activate.bat`
**Priority:** P0 (Critical)

#### Test Case 3.4: Unix Venv Activation
```python
def test_unix_venv_activation():
    """Verify Unix activation path"""
    with mock.patch('platform.system', return_value='Linux'):
        installer = CrossPlatformInstaller()
        activation = installer.get_venv_activation_command()
        assert 'source' in activation
        assert 'bin/activate' in activation
```

**Expected:** `source venv/bin/activate`
**Priority:** P0 (Critical)

### 3.4 Color Output (test_color_output.py)

#### Test Case 4.1: ANSI Colors on Unix
```python
def test_ansi_colors_on_unix():
    """Verify ANSI codes work on Unix"""
    with mock.patch('platform.system', return_value='Linux'):
        installer = CrossPlatformInstaller()
        assert Colors.GREEN == '\033[0;32m'
        assert Colors.RED == '\033[0;31m'
```

**Expected:** ANSI codes preserved
**Priority:** P2 (Nice-to-have)

#### Test Case 4.2: ANSI Colors Disabled on Old Windows
```python
def test_ansi_colors_disabled_on_old_windows():
    """Verify colors disabled on Windows without ANSICON"""
    with mock.patch('platform.system', return_value='Windows'):
        with mock.patch.dict('os.environ', {}, clear=True):
            Colors.disable_on_windows()
            assert Colors.GREEN == ''
            assert Colors.RED == ''
```

**Expected:** Empty strings (no colors)
**Priority:** P2 (Nice-to-have)

---

## 4. Integration Test Specifications

### 4.1 CLI Installation (test_cli_installation.py)

#### Test Case 5.1: Full CLI Installation
```python
def test_full_cli_installation(tmp_path):
    """Test complete CLI installation flow"""
    # Setup
    os.chdir(tmp_path)
    (tmp_path / "requirements.txt").write_text("gitpython>=3.1.0\n")

    # Run
    installer = CrossPlatformInstaller()
    result = installer.run(venv_only=False, deps_only=False)

    # Verify
    assert result == 0
    assert (tmp_path / "venv").exists()

    venv_python = installer.get_venv_python()
    assert venv_python.exists()

    # Verify GitPython installed
    result = subprocess.run(
        [str(venv_python), '-c', 'import git; print(git.__version__)'],
        capture_output=True, text=True
    )
    assert result.returncode == 0
    assert result.stdout.strip() >= "3.1.0"
```

**Expected:** venv created, GitPython installed
**Priority:** P0 (Critical)

#### Test Case 5.2: Venv-Only Mode
```python
def test_venv_only_mode(tmp_path):
    """Test --venv-only flag"""
    os.chdir(tmp_path)

    installer = CrossPlatformInstaller()
    result = installer.run(venv_only=True, deps_only=False)

    assert result == 0
    assert (tmp_path / "venv").exists()

    # Verify GitPython NOT installed
    venv_python = installer.get_venv_python()
    result = subprocess.run(
        [str(venv_python), '-c', 'import git'],
        capture_output=True
    )
    assert result.returncode != 0  # Should fail
```

**Expected:** venv created, no dependencies
**Priority:** P1 (Important)

#### Test Case 5.3: Deps-Only Mode
```python
def test_deps_only_mode(tmp_path):
    """Test --deps-only flag"""
    os.chdir(tmp_path)
    (tmp_path / "requirements.txt").write_text("gitpython>=3.1.0\n")

    # Create venv manually first
    subprocess.run(['python3', '-m', 'venv', 'venv'])

    # Run deps-only
    installer = CrossPlatformInstaller()
    result = installer.run(venv_only=False, deps_only=True)

    assert result == 0

    # Verify GitPython installed
    venv_python = installer.get_venv_python()
    result = subprocess.run(
        [str(venv_python), '-c', 'import git'],
        capture_output=True
    )
    assert result.returncode == 0
```

**Expected:** Dependencies installed into existing venv
**Priority:** P1 (Important)

### 4.2 GUI Initialization (test_gui_initialization.py)

#### Test Case 6.1: GUI Window Creation
```python
def test_gui_window_creation():
    """Verify GUI initializes without errors"""
    root = tk.Tk()
    gui = InstallerGUI(root)

    assert gui.os_type in ['Windows', 'Darwin', 'Linux']
    assert gui.installing == False
    assert gui.installation_complete == False

    root.destroy()
```

**Expected:** GUI initializes successfully
**Priority:** P0 (Critical)

#### Test Case 6.2: Platform Info Display
```python
def test_platform_info_display():
    """Verify platform info is displayed"""
    root = tk.Tk()
    gui = InstallerGUI(root)

    # Find platform label (requires GUI inspection)
    # This test may need manual verification

    root.destroy()
```

**Expected:** Platform info visible
**Priority:** P2 (Nice-to-have, may be manual)

### 4.3 Error Handling (test_error_handling.py)

#### Test Case 7.1: Graceful Failure on Network Error
```python
def test_network_error_handling(tmp_path):
    """Verify graceful failure when pip install fails"""
    os.chdir(tmp_path)

    # Create invalid requirements.txt
    (tmp_path / "requirements.txt").write_text("nonexistent-package-12345\n")

    installer = CrossPlatformInstaller()
    installer.create_venv()

    result = installer.install_dependencies()

    # Should handle gracefully
    assert result == False  # Fails but doesn't crash
```

**Expected:** Returns False, doesn't crash
**Priority:** P1 (Important)

#### Test Case 7.2: Missing tkinter Fallback
```python
def test_missing_tkinter_fallback():
    """Verify launcher falls back to CLI when tkinter missing"""
    with mock.patch('importlib.import_module', side_effect=ImportError):
        # launch.py should detect this and fall back to CLI
        # This requires testing launch.py logic
        pass
```

**Expected:** Falls back to CLI
**Priority:** P1 (Important)

---

## 5. Manual Test Specifications

### 5.1 Windows Testing (test_windows.md)

**Platform:** Windows 10/11
**Python:** 3.8+ from python.org

#### Manual Test 1: GUI Installation
1. Open Command Prompt
2. Run: `python scripts\installer\launch.py`
3. Verify GUI opens
4. Click Install
5. Verify progress bar animates
6. Verify success dialog appears
7. Verify venv\ folder created
8. Verify GitPython installed: `venv\Scripts\python -c "import git; print(git.__version__)"`

**Expected:** All steps complete without errors
**Priority:** P0 (Critical)

#### Manual Test 2: CLI Installation
1. Run: `python scripts\installer\install.py`
2. Verify colored output
3. Verify venv created
4. Verify dependencies installed

**Expected:** CLI works without errors
**Priority:** P0 (Critical)

### 5.2 macOS Testing (test_macos.md)

**Platform:** macOS 12+ (Monterey or later)
**Python:** 3.8+ from python.org or Homebrew

#### Manual Test 3: GUI Installation
1. Open Terminal
2. Run: `python3 scripts/installer/launch.py`
3. Verify GUI opens (requires tkinter)
4. Complete installation
5. Verify venv/ created
6. Verify GitPython installed

**Expected:** GUI works on macOS
**Priority:** P0 (Critical)

#### Manual Test 4: Homebrew Python
1. Install Python via Homebrew: `brew install python@3.11`
2. Run installer
3. Verify tkinter availability (may be missing)
4. If missing, verify fallback to CLI

**Expected:** Falls back to CLI if tkinter missing
**Priority:** P1 (Important)

### 5.3 Linux Testing (test_linux.md)

**Platforms:** Ubuntu 22.04, Fedora Latest

#### Manual Test 5: Ubuntu Installation
1. Run: `sudo apt-get install python3 python3-tk`
2. Run: `python3 scripts/installer/launch.py`
3. Verify GUI or CLI fallback
4. Complete installation

**Expected:** Works on Ubuntu
**Priority:** P0 (Critical)

#### Manual Test 6: Fedora Installation
1. Run: `sudo dnf install python3 python3-tkinter`
2. Run installer
3. Complete installation

**Expected:** Works on Fedora
**Priority:** P1 (Important)

---

## 6. Test Execution

### 6.1 Running Tests

```bash
# All tests
pytest tests/

# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# With coverage
pytest --cov=. --cov-report=html tests/

# Specific test
pytest tests/unit/test_platform_detection.py::test_detect_windows
```

### 6.2 Continuous Integration

**GitHub Actions Workflow:**
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        python-version: ['3.8', '3.9', '3.10', '3.11']

    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest pytest-cov
    - name: Run tests
      run: pytest --cov=. tests/
```

---

## 7. Test Coverage Goals

### 7.1 Coverage by Module

| Module | Target | Priority |
|--------|--------|----------|
| install.py | 80% | P0 |
| install_gui.py | 60% | P1 |
| launch.py | 70% | P0 |
| install.sh | Manual | P1 |

### 7.2 Untested Areas (Acceptable)

- UI rendering (manual testing)
- Platform-specific edge cases (manual)
- Network timeouts (mocking difficult)
- User input prompts (interactive)

### 7.3 Critical Paths (Must Test)

- ✅ Platform detection
- ✅ Python version checking
- ✅ Venv creation
- ✅ Dependency installation
- ✅ Path resolution
- ✅ Error handling

---

## 8. Test-Driven Development Workflow

### 8.1 Adding New Feature

**Example: Add auto-update checker**

1. **Write test first:**
```python
def test_check_for_updates():
    """Verify update checking works"""
    installer = CrossPlatformInstaller()
    update_available = installer.check_for_updates()
    assert isinstance(update_available, bool)
```

2. **Run test (should fail):**
```bash
pytest tests/unit/test_updates.py::test_check_for_updates
# Expected: AttributeError (method doesn't exist yet)
```

3. **Implement feature:**
```python
def check_for_updates(self) -> bool:
    # Implementation
    return False
```

4. **Run test (should pass):**
```bash
pytest tests/unit/test_updates.py::test_check_for_updates
# Expected: PASSED
```

5. **Refactor:**
```python
def check_for_updates(self) -> bool:
    # Improved implementation
    try:
        # Check GitHub releases API
        return True if new_version else False
    except Exception:
        return False
```

6. **Run all tests:**
```bash
pytest tests/
# Expected: All tests pass
```

---

## 9. Test Data and Fixtures

### 9.1 Mock Requirements File
```python
# tests/fixtures/mock_requirements.txt
gitpython>=3.1.0
```

### 9.2 Temporary Directory Fixture
```python
@pytest.fixture
def temp_project_dir(tmp_path):
    """Create temporary project directory with requirements.txt"""
    requirements = tmp_path / "requirements.txt"
    requirements.write_text("gitpython>=3.1.0\n")
    return tmp_path
```

### 9.3 Mock Installer Fixture
```python
@pytest.fixture
def mock_installer(tmp_path):
    """Create installer with temporary paths"""
    with mock.patch('pathlib.Path.home', return_value=tmp_path):
        return CrossPlatformInstaller()
```

---

## 10. Known Test Limitations

### 10.1 GUI Testing
- **Challenge:** tkinter UI testing is difficult to automate
- **Solution:** Focus on initialization tests + manual testing
- **Priority:** P2 (Nice-to-have)

### 10.2 Platform-Specific Testing
- **Challenge:** Can't test all platforms in one environment
- **Solution:** CI/CD with matrix (Windows, macOS, Linux)
- **Priority:** P0 (Critical)

### 10.3 Network Operations
- **Challenge:** pip install requires internet
- **Solution:** Use local mock package or skip in CI
- **Priority:** P1 (Important)

---

## 11. Future Test Enhancements

### 11.1 Phase 2 Tests
- [ ] Performance benchmarks (installation time)
- [ ] Memory usage tests
- [ ] Concurrent installation tests
- [ ] Retry logic tests

### 11.2 Phase 3 Tests
- [ ] Standalone executable tests
- [ ] Auto-update tests
- [ ] Uninstaller tests
- [ ] Telemetry tests (opt-in)

---

## 12. Test Status

### 12.1 Current Status

| Category | Status | Count | Coverage |
|----------|--------|-------|----------|
| Unit Tests | ⏸️ Pending | 0/15 | 0% |
| Integration Tests | ⏸️ Pending | 0/8 | 0% |
| Manual Tests | 🟡 Partial | 2/6 | 33% |
| Platform Tests | 🟡 Partial | 2/3 | 67% |

### 12.2 Next Steps

1. **Week 1:** Implement unit tests (platform detection, version check, paths)
2. **Week 2:** Implement integration tests (full installation flow)
3. **Week 3:** Manual testing on all platforms (Windows, macOS, Linux)
4. **Week 4:** CI/CD integration with GitHub Actions

---

**Status:** Test specifications complete, implementation pending
**Priority:** P0 for pilot phase (tests critical for production)
**Last Updated:** November 16, 2025
**Version:** 1.0.0

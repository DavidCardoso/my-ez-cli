# My Ez CLI - Test Suite

Comprehensive test suite for My Ez CLI using [bats-core](https://github.com/bats-core/bats-core).

---

## 📊 Test Coverage

| Category | Tests | Files | Status |
|----------|-------|-------|--------|
| Unit Tests | 65 | 8 | ✅ |
| Integration Tests | 8 | 2 | ✅ |
| **Total** | **73** | **10** | **✅** |

---

## 📁 Directory Structure

```
tests/
├── unit/                      # Unit tests (65 tests)
│   ├── test-aws.bats          # AWS CLI wrapper tests (4)
│   ├── test-common-utils.bats # Common utilities tests (10)
│   ├── test-node.bats         # Node.js wrapper tests (8)
│   ├── test-npm.bats          # NPM wrapper tests (5)
│   ├── test-python.bats       # Python wrapper tests (5)
│   ├── test-setup.bats        # Setup script tests (18)
│   ├── test-terraform.bats    # Terraform wrapper tests (5)
│   └── test-yarn.bats         # Yarn wrapper tests (10)
├── integration/               # Integration tests (8 tests)
│   ├── test-node-port-binding.bats
│   └── test-symlink-execution.bats
├── e2e/                       # End-to-end tests (planned)
├── helpers/                   # Shared test helpers (future)
├── fixtures/                  # Test data/fixtures (future)
├── check-dependencies.sh      # Dependency checker
├── setup-test-env.sh          # Auto-install dependencies
├── run-all-tests.sh           # Main test runner
└── README.md                  # This file
```

---

## 🚀 Quick Start

### 1. Check Dependencies

```bash
./tests/check-dependencies.sh
```

**Required:**
- Docker (with daemon running)
- bats-core (test framework)
- bash (4.0+)

**Optional:**
- git (for version info)

### 2. Install Dependencies

**Auto-install (macOS/Linux):**
```bash
./tests/setup-test-env.sh
```

**Manual install:**
```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Fedora/RHEL
sudo dnf install bats

# Manual
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### 3. Run Tests

**All tests:**
```bash
./tests/run-all-tests.sh
```

**Specific test file:**
```bash
bats tests/unit/test-node.bats
bats tests/unit/test-setup.bats
```

**Unit tests only:**
```bash
bats tests/unit/*.bats
```

**Integration tests only:**
```bash
bats tests/integration/*.bats
```

**Skip dependency check:**
```bash
SKIP_DEPENDENCY_CHECK=1 ./tests/run-all-tests.sh
```

---

## 📝 Test Details

### Unit Tests (65 tests)

**test-aws.bats (4 tests)**
- Script existence and executability
- Version checking
- Common.sh sourcing
- Help command functionality

**test-common-utils.bats (10 tests)**
- File existence
- Source loading
- TTY flag detection
- Port binding helpers
- Docker availability check
- Logging setup
- Version constants

**test-node.bats (8 tests)**
- Default Node.js v22
- JavaScript execution
- Multi-version support (14, 16, 18, 20, 22)
- Script syntax validation

**test-npm.bats (5 tests)**
- NPM availability
- Package listing
- Cache folder creation
- Common.sh integration

**test-python.bats (5 tests)**
- Python execution
- Code execution
- Standard library imports
- Version checking

**test-setup.bats (18 tests)**
- Command-line interface (help, status, list)
- Error handling
- Install/uninstall functions
- Tracking system
- Verification functions
- Interactive menu
- Tool availability

**test-terraform.bats (5 tests)**
- Version checking
- Help command
- Script syntax
- Common.sh integration

**test-yarn.bats (10 tests)**
- Yarn wrapper functionality
- Multi-version support (14, 16, 18, 20, 22)
- Yarn Berry support
- Help commands

### Integration Tests (8 tests)

**test-node-port-binding.bats (2 tests)**
- MEC_BIND_PORTS environment variable
- Port flag generation

**test-symlink-execution.bats (6 tests)**
- Symlink creation and execution
- Path resolution
- Multi-tool symlink support

---

## 🛠️ Writing Tests

### Test File Template

```bash
#!/usr/bin/env bats

# Test description

setup() {
    # Runs before each test
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

teardown() {
    # Runs after each test (optional)
    # Cleanup code here
}

@test "descriptive test name" {
    # Test code here
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected pattern" ]]
}
```

### Best Practices

1. **Use descriptive test names**
   ```bash
   @test "node runs with default version 22" {
   ```

2. **Use `run` for command execution**
   ```bash
   run "$BASEDIR/bin/node" --version
   [ "$status" -eq 0 ]
   ```

3. **Check both status and output**
   ```bash
   [ "$status" -eq 0 ]
   [[ "$output" =~ "v22" ]]
   ```

4. **Skip tests conditionally**
   ```bash
   if ! docker images | grep -q "image-name"; then
       skip "Docker image not built yet"
   fi
   ```

5. **Use setup/teardown for shared code**
   ```bash
   setup() {
       export TEST_VAR="value"
   }

   teardown() {
       rm -f /tmp/test-file
   }
   ```

---

## 🔧 Dependencies

### Required

**bats-core** (v1.0.0+)
- Test framework
- Homepage: https://github.com/bats-core/bats-core
- License: MIT
- Purpose: Running bash-based tests

**Docker** (v20.0+)
- Container runtime
- Homepage: https://docker.com
- License: Apache 2.0
- Purpose: Running tool wrappers in containers

**bash** (v4.0+)
- Shell interpreter
- Purpose: Running scripts and tests

### Optional

**git**
- Version control
- Purpose: Commit info in tests

---

## 🐛 Troubleshooting

### Tests fail with "bats: command not found"

**Solution:** Install bats-core
```bash
./tests/setup-test-env.sh
```

### Tests fail with "Docker daemon not running"

**Solution:** Start Docker
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

### Tests fail with "Permission denied"

**Solution:** Ensure scripts are executable
```bash
chmod +x tests/*.sh
chmod +x bin/*
```

### Specific tool test fails

**Solution:** Check if Docker image exists
```bash
docker images | grep <image-name>
```

For custom images, build them first:
```bash
docker build -t my-ez-cli/yarn-berry docker/yarn-berry/
```

### Tests pass locally but fail in CI

**Possible causes:**
1. Different OS (Ubuntu vs macOS)
2. Docker not available
3. Permission issues

**Solution:** Check GitHub Actions logs and compare environments

---

## 🔄 CI/CD Integration

Tests run automatically with optimizations for speed and reliability.

### Test Levels

**PR (Pull Requests):**
- ✓ Smoke tests (syntax checks, basic validations)
- ✓ Unit tests (parallel execution)
- ✗ Integration tests (skipped for speed)

**Main Branch:**
- ✓ Smoke tests
- ✓ Unit tests (parallel)
- ✓ Integration tests

**Releases:**
- ✓ Smoke tests
- ✓ Unit tests (parallel)
- ✓ Integration tests

### Workflow Structure

**Workflow file:** `.github/workflows/test.yml`

**Jobs:**
1. **setup** - Pre-pulls and caches Docker images (node:14-24, python, terraform, aws-cli)
2. **smoke-tests** - Fast syntax checks and basic validations (~30 seconds)
3. **unit-tests** - 8 test suites run in parallel using matrix strategy (~2 minutes)
4. **integration-tests** - Port binding and symlink tests (main/release only, ~1 minute)
5. **summary** - Aggregates results with status table

### Performance Optimizations

**Docker Image Caching:**
```yaml
- name: Cache Docker images
  uses: actions/cache@v3
  with:
    path: /tmp/docker-images
    key: ${{ runner.os }}-docker-${{ hashFiles('.github/workflows/test.yml') }}-v1
```

**Parallel Test Execution:**
```yaml
strategy:
  fail-fast: false
  matrix:
    test-suite: [aws, common-utils, node, npm, python, setup, terraform, yarn]
```

**Pre-pull Images in Parallel:**
```bash
for img in $NODE_IMAGES; do
  docker pull $img &
done
wait
```

### Estimated Execution Times

| Event Type | Tests Run | Duration (cold) | Duration (cached) |
|------------|-----------|-----------------|-------------------|
| PR | Smoke + Unit | ~5 minutes | ~2 minutes |
| Main/Release | Smoke + Unit + Integration | ~6 minutes | ~3 minutes |

**Note:** Custom Docker images (yarn-berry, serverless, cdktf, aws-sso-cred, speedtest) are NOT tested in CI to avoid long build times. These are tested separately in their respective docker-build-* workflows.

### Skip Dependency Check

CI automatically skips local dependency checks:
```yaml
env:
  SKIP_DEPENDENCY_CHECK: 1
```

---

## 📈 Test Statistics

```bash
# Run tests with timing info
time ./tests/run-all-tests.sh

# Count tests per file
grep -c "^@test" tests/unit/*.bats tests/integration/*.bats

# List all test names
grep "^@test" tests/unit/*.bats tests/integration/*.bats
```

---

## 🎯 Future Enhancements

### Planned (Phase 2+)

- [ ] **End-to-end tests** - Full workflow testing
- [ ] **Performance tests** - Container startup time benchmarks
- [ ] **Test helpers** - Shared utilities for complex scenarios
- [ ] **Test fixtures** - Sample files and data for testing
- [ ] **Coverage reports** - Test coverage metrics
- [ ] **Parallel execution** - Faster test runs
- [ ] **Test categories** - Tagged tests (smoke, regression, etc.)

### Ideas

- Test data generators
- Mock Docker responses
- Network simulation tests
- Resource cleanup verification
- Multi-platform specific tests

---

## 📚 References

### Documentation

- [bats-core Documentation](https://bats-core.readthedocs.io/)
- [Bash Testing Tutorial](https://github.com/bats-core/bats-core#tutorials)
- [TAP Protocol](https://testanything.org/)

### Examples

- [bats-core Examples](https://github.com/bats-core/bats-core/tree/master/test)
- [Bash Best Practices](https://github.com/progrium/bashstyle)

### Tools

- [shellcheck](https://www.shellcheck.net/) - Shell script linter
- [shfmt](https://github.com/mvdan/sh) - Shell script formatter

---

## 💡 Tips

1. **Run single test for debugging:**
   ```bash
   bats tests/unit/test-node.bats --filter "node runs"
   ```

2. **Verbose output:**
   ```bash
   bats tests/unit/test-node.bats --verbose
   ```

3. **Tap output:**
   ```bash
   bats tests/unit/test-node.bats --tap
   ```

4. **Pretty formatting:**
   ```bash
   bats tests/unit/test-node.bats --pretty
   ```

5. **Stop on first failure:**
   ```bash
   bats tests/unit/test-node.bats --no-parallelize-across-files
   ```

---

## 🤝 Contributing

When adding new tests:

1. Place unit tests in `tests/unit/`
2. Place integration tests in `tests/integration/`
3. Follow naming convention: `test-<component>.bats`
4. Add test documentation to this README
5. Ensure all tests pass before committing
6. Update test count in this README

---

## 📄 License

Same as My Ez CLI - See parent LICENSE file

---

*Last updated: 2025-11-20*
*Test framework version: 1.0.0-alpha*

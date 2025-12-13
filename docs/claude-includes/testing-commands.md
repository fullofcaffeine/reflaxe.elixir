# Essential Testing Commands

## 🚀 Quick Test Commands

### Full Test Suite
```bash
npm test                          # Complete test suite (mandatory before commit)
```

### Specific Test Categories  
```bash
make -C test test-name                     # Run specific snapshot test
make -C test update-intended TEST=name     # Accept new compiler output
MIX_ENV=test mix test                      # Runtime validation tests
```

### Integration Testing
```bash
# Todo-app integration (primary benchmark, non-blocking + bounded)
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 60
```

### Performance Testing
```bash
npm run test:parallel                     # Parallel test execution
timeout 30 npm test                       # Test with timeout
```

## 🔍 Test Analysis Commands

### Build System
```bash
mix deps.get                              # Install Elixir dependencies
mix compile                               # Standard Elixir compilation
mix format                                # Code formatting
```

### Development Workflow
```bash
# Debugging
mix compile --verbose                     # Verbose compilation output
MIX_ENV=test mix compile --force          # Force recompilation
```

## ⚠️ Critical Test Rules

- **NEVER commit without running `npm test`**
- **Todo-app MUST compile as integration validation**
- **ALL tests must pass before moving to new features**
- **Update snapshots only when compiler output legitimately improves**
- **Fix broken tests immediately, don't ignore as "unrelated"**

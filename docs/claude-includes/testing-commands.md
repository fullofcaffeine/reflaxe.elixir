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
# Todo-app integration (primary benchmark)
cd examples/todo-app
rm -rf lib/*.ex lib/**/*.ex               # Clean generated files
npx haxe build-server.hxml                # Regenerate from Haxe
mix compile --force                       # Verify Elixir compilation
mix phx.server                            # Test application starts

# Test response
curl http://localhost:4000/ | grep TodoApp
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
# Watch mode (if available)
mix test --watch                          # Auto-run tests on change
mix phx.server --watch                    # Auto-reload server

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
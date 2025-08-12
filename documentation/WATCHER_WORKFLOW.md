# File Watching & Incremental Compilation Workflow

## Overview

Reflaxe.Elixir provides a powerful development workflow with automatic file watching and incremental compilation, enabling sub-second rebuild times for rapid development iteration. This guide covers both manual development and LLM-assisted workflows.

> 📚 **For comprehensive tutorials and project-specific examples, see the [Watcher Development Guide](guides/WATCHER_DEVELOPMENT_GUIDE.md)** which includes step-by-step setups for Phoenix, LiveView, and Umbrella applications.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Development Workflows](#development-workflows)
4. [LLM Agent Integration](#llm-agent-integration)
5. [Configuration](#configuration)
6. [Performance Optimization](#performance-optimization)
7. [Troubleshooting](#troubleshooting)

## Quick Start

> **New to the watcher?** Check out the [Quick Start section](guides/WATCHER_DEVELOPMENT_GUIDE.md#quick-start) in the development guide for a 30-second setup!

### Basic File Watching

```bash
# Start compilation with file watching
mix compile.haxe --watch

# Or use Phoenix development server (includes watching)
mix phx.server
```

Now any changes to `.hx` files in `src_haxe/` trigger automatic recompilation!

### With Source Mapping

```bash
# Enable both watching and source mapping
mix compile.haxe --watch --verbose

# In your compile.hxml, ensure source mapping is enabled:
# -D source-map
```

## Architecture

### Components

#### 1. HaxeWatcher (GenServer)
- Monitors `.hx` files for changes using FileSystem
- Debounces rapid changes (default: 100ms)
- Triggers compilation through HaxeServer
- Configurable watch directories and patterns

#### 2. HaxeServer (GenServer)
- Manages Haxe compiler in `--wait` mode
- Maintains compilation server on port 6000
- Provides incremental compilation (caches parsed files)
- Dramatically faster than cold compilation

#### 3. Mix.Tasks.Compile.Haxe
- Integrates with Mix build pipeline
- Starts HaxeWatcher when `--watch` flag present
- Manages compilation manifest for dependency tracking
- Handles error reporting and source mapping

### How It Works

```
File Change → HaxeWatcher (debounce) → HaxeServer → Incremental Compilation → Generated .ex files
                    ↓                       ↓                ↓
             FileSystem events       haxe --wait 6000   Source maps (.ex.map)
```

## Development Workflows

> 🎯 **Looking for specific project examples?** The [Development Guide](guides/WATCHER_DEVELOPMENT_GUIDE.md#project-specific-setups) has detailed setups for:
> - Basic Mix projects
> - Phoenix web applications  
> - Phoenix LiveView apps
> - Umbrella applications

### Workflow 1: Traditional Development

1. **Start the watcher**
   ```bash
   mix compile.haxe --watch
   ```

2. **Edit Haxe files**
   ```haxe
   // src_haxe/UserService.hx
   class UserService {
       public static function getUser(id: Int): User {
           // Make changes here
       }
   }
   ```

3. **See immediate feedback**
   ```
   [HaxeWatcher] File changed: src_haxe/UserService.hx
   [HaxeCompiler] Compiling...
   Compiled 1 Haxe file(s) in 0.3s
   ```

4. **Debug with source mapping**
   ```bash
   # If there's an error, it shows Haxe source position
   src_haxe/UserService.hx:23: Type not found : UserModel
   ```

### Workflow 2: Phoenix LiveView Development

1. **Start Phoenix with watching**
   ```bash
   # This starts both Phoenix and HaxeWatcher
   iex -S mix phx.server
   ```

2. **Edit LiveView components**
   ```haxe
   // src_haxe/live/CounterLive.hx
   @:liveview
   class CounterLive {
       function handle_event("increment", _params, socket) {
           // Changes here trigger recompilation
           // Phoenix LiveReloader picks up changes
       }
   }
   ```

3. **Browser auto-reloads**
   - HaxeWatcher compiles .hx → .ex
   - Phoenix LiveReloader detects .ex changes
   - Browser refreshes automatically

### Workflow 3: Test-Driven Development

1. **Run tests with watching**
   ```bash
   # In one terminal
   mix compile.haxe --watch
   
   # In another terminal
   mix test.watch
   ```

2. **Write test first**
   ```haxe
   // test_haxe/UserServiceTest.hx
   class UserServiceTest {
       function testGetUser() {
           var user = UserService.getUser(1);
           Assert.equals("Alice", user.name);
       }
   }
   ```

3. **Implementation triggers recompilation**
   ```haxe
   // src_haxe/UserService.hx
   class UserService {
       public static function getUser(id: Int): User {
           // Implementation auto-recompiles
           return new User("Alice");
       }
   }
   ```

## LLM Agent Integration

> 🤖 **Using Claude CLI or other AI assistants?** See the comprehensive [Claude CLI Integration](guides/WATCHER_DEVELOPMENT_GUIDE.md#claude-cli-integration-agentic-development) section for:
> - Auto-fix error workflows
> - Iterative feature development patterns
> - Safe refactoring with continuous validation
> - Multi-file coordination examples

### Setup for LLM Development

1. **Configure for LLM mode**
   ```elixir
   # config/dev.exs
   config :reflaxe_elixir,
     watcher: [
       auto_compile: true,
       debounce_ms: 500,    # Longer debounce for LLM edits
       verbose: false,       # Less noise for agents
       json_output: true     # Structured output
     ]
   ```

2. **Start watcher with LLM flags**
   ```bash
   mix compile.haxe --watch --llm-mode
   ```

### LLM Workflow Pattern

1. **Agent monitors compilation status**
   ```bash
   # Agent queries current status
   mix haxe.status --format json
   
   # Response
   {
     "watching": true,
     "last_compilation": "2025-08-11T10:30:45Z",
     "files_compiled": 3,
     "errors": []
   }
   ```

2. **Agent makes changes**
   ```javascript
   // LLM makes edit to fix error
   await editFile('src_haxe/UserService.hx', fixes);
   
   // Watcher automatically triggers compilation
   ```

3. **Agent verifies fix**
   ```bash
   # Agent checks if error is resolved
   mix haxe.errors --format json
   
   # If errors remain, agent continues iteration
   ```

### Autonomous Development Loop

```javascript
// LLM Agent autonomous development loop
async function developFeature(specification) {
    // Start watcher
    await exec('mix compile.haxe --watch --llm-mode');
    
    while (!featureComplete(specification)) {
        // Make changes
        const changes = planChanges(specification);
        await applyChanges(changes);
        
        // Wait for compilation (watcher triggers automatically)
        await waitForCompilation();
        
        // Check results
        const errors = await getErrors();
        if (errors.length > 0) {
            const fixes = analyzaeErrors(errors);
            await applyFixes(fixes);
        }
        
        // Run tests
        const testResults = await runTests();
        if (!testResults.passing) {
            await fixFailingTests(testResults);
        }
    }
}
```

### Best Practices for LLM Agents

1. **Use longer debounce periods** - Prevents compilation during multi-file edits
2. **Monitor compilation events** - Wait for completion before checking results
3. **Leverage source mapping** - Use precise positions for fixes
4. **Batch related changes** - Edit multiple files before compilation triggers

## Configuration

### HaxeWatcher Configuration

```elixir
# Start with custom configuration
{:ok, pid} = HaxeWatcher.start_link([
  dirs: ["src_haxe", "lib_haxe"],           # Directories to watch
  patterns: ["**/*.hx", "**/*.hxml"],       # File patterns
  debounce_ms: 200,                         # Debounce period
  auto_compile: true,                       # Auto-trigger compilation
  verbose: true                             # Verbose output
])
```

### HaxeServer Configuration

```elixir
# Configure the compilation server
{:ok, pid} = HaxeServer.start_link([
  port: 6000,                               # Server port
  timeout: 30_000,                          # Compilation timeout
  haxe_cmd: "npx haxe",                     # Haxe command
  cache_enabled: true,                      # Enable caching
  incremental: true                         # Use incremental compilation
])
```

### Mix Configuration

```elixir
# In mix.exs
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      watch_dirs: ["src_haxe"],
      source_map: true,
      incremental: true,
      verbose: Mix.env() == :dev
    ]
  ]
end
```

### compile.hxml Configuration

```hxml
# Enable features for development
-cp src_haxe
-lib reflaxe
-main Main
-D elixir_output=lib
-D source-map          # Enable source mapping
-D incremental        # Support incremental compilation
-D watch-mode         # Optimize for watching
```

## Performance Optimization

> 📊 **Want real-world benchmarks?** Check out the [Performance & Benchmarks](guides/WATCHER_DEVELOPMENT_GUIDE.md#performance--benchmarks) section for metrics from actual projects.

### Incremental Compilation Performance

| Scenario | Cold Compile | Incremental | Improvement |
|----------|--------------|-------------|-------------|
| Single file change | 2-5s | 0.1-0.3s | 10-50x |
| Multiple files | 5-10s | 0.3-1s | 10-15x |
| Full rebuild | 10-20s | 10-20s | 1x |

### Optimization Tips

1. **Keep watch directories focused**
   ```elixir
   # Watch only source directories
   dirs: ["src_haxe"]  # Don't watch "test_haxe" in dev
   ```

2. **Use appropriate debounce**
   ```elixir
   # For human development
   debounce_ms: 100
   
   # For LLM agents
   debounce_ms: 500
   ```

3. **Exclude generated files**
   ```elixir
   # Don't watch output directories
   patterns: ["**/*.hx", "!out/**", "!lib/**"]
   ```

4. **Optimize compilation flags**
   ```hxml
   # Development mode
   -D skip-optimization
   -D fast-cast
   --no-inline
   ```

## Troubleshooting

> 🔧 **Need platform-specific help?** The [Troubleshooting Guide](guides/WATCHER_DEVELOPMENT_GUIDE.md#troubleshooting) covers:
> - macOS FSEvents configuration
> - Linux inotify limits
> - Windows polling setup
> - Docker/container considerations

### Issue: Watcher not detecting changes

**Symptoms**: File edits don't trigger recompilation

**Solutions**:
1. Check watched directories:
   ```elixir
   HaxeWatcher.status()
   # Should show watched directories
   ```

2. Verify file patterns match:
   ```bash
   # Ensure your files match patterns
   ls src_haxe/**/*.hx
   ```

3. Check FileSystem backend:
   ```elixir
   # Some systems need polling
   config :file_system, :fs_inotify, enabled: false
   config :file_system, :fs_poll, enabled: true
   ```

### Issue: Compilation server crashes

**Symptoms**: "Could not connect to compilation server"

**Solutions**:
1. Restart the server:
   ```elixir
   HaxeServer.stop()
   {:ok, _} = HaxeServer.start_link()
   ```

2. Check port availability:
   ```bash
   lsof -i :6000
   # Should be free or used by haxe
   ```

3. Increase timeout:
   ```elixir
   HaxeServer.start_link([timeout: 60_000])
   ```

### Issue: Slow incremental compilation

**Symptoms**: Incremental builds not much faster than cold

**Solutions**:
1. Verify server is running:
   ```elixir
   HaxeServer.running?()  # Should be true
   ```

2. Check cache effectiveness:
   ```bash
   # Look for "Using cached" messages
   mix compile.haxe --verbose
   ```

3. Clear cache if corrupted:
   ```bash
   rm -rf .haxe-cache
   mix compile.haxe --force
   ```

### Issue: Memory usage grows over time

**Symptoms**: Haxe server consumes increasing memory

**Solutions**:
1. Restart server periodically:
   ```elixir
   # In dev, restart every hour
   Process.send_after(self(), :restart_server, :timer.hours(1))
   ```

2. Limit cache size:
   ```hxml
   --macro haxe.macro.Context.setCacheSize(100)
   ```

## Advanced Features

### Custom File Processors

```elixir
# Add custom processing for certain files
HaxeWatcher.add_processor(fn path ->
  if String.ends_with?(path, ".hxml") do
    # Special handling for build files
    Mix.Task.run("compile.haxe", ["--force"])
  end
end)
```

### Compilation Hooks

```elixir
# Run actions after successful compilation
HaxeCompiler.add_hook(:after_compile, fn result ->
  if result.success? do
    Mix.Task.run("test", ["--stale"])
  end
end)
```

### Watch Status API

```elixir
# Get detailed watch status
status = HaxeWatcher.detailed_status()

IO.inspect(status)
# %{
#   watching: true,
#   directories: ["src_haxe"],
#   patterns: ["**/*.hx"],
#   last_change: ~U[2025-08-11 10:30:45Z],
#   pending_compilation: false,
#   total_compilations: 42
# }
```

## Integration Examples

### VS Code Task

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start Haxe Watcher",
      "type": "shell",
      "command": "mix compile.haxe --watch",
      "isBackground": true,
      "problemMatcher": {
        "pattern": {
          "regexp": "^(.+\\.hx):(\\d+): (.+)$",
          "file": 1,
          "line": 2,
          "message": 3
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^\\[HaxeWatcher\\] File changed",
          "endsPattern": "^Compiled \\d+ Haxe file"
        }
      }
    }
  ]
}
```

### GitHub Actions CI

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Haxe
        run: |
          npm install
          npx lix download
      
      - name: Compile with watching disabled
        run: |
          mix compile.haxe --no-watch
      
      - name: Run tests
        run: mix test
```

## Summary

The file watching and incremental compilation workflow provides:

- ⚡ **Sub-second recompilation** for rapid iteration
- 🤖 **LLM-friendly** with structured output and status APIs
- 🔄 **Seamless integration** with Phoenix LiveReloader
- 📍 **Source mapping** support for precise debugging
- 🎯 **Configurable** for different development styles
- 🚀 **Production-ready** performance optimizations

Combined with source mapping, this creates a powerful development experience that rivals or exceeds native Elixir development while maintaining Haxe's type safety benefits.

## Related Documentation

- 📚 [Watcher Development Guide](guides/WATCHER_DEVELOPMENT_GUIDE.md) - Comprehensive tutorials and examples
- 🗺️ [Source Mapping Guide](SOURCE_MAPPING.md) - Debugging with source maps
- 🚀 [Getting Started](guides/GETTING_STARTED.md) - First steps with Reflaxe.Elixir
- 📖 [Tutorial: First Project](guides/TUTORIAL_FIRST_PROJECT.md) - Step-by-step project creation
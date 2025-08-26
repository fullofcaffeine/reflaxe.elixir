# FileSystem On-Demand Loading Design

## Overview

The `:file_system` dependency is configured for on-demand loading, making it an optional dependency that only loads when file watching functionality is needed. This design keeps the core Reflaxe.Elixir library lightweight while providing advanced features when required.

## Architecture

### Dependency Configuration

In `mix.exs`:
```elixir
defp deps do
  [
    {:jason, "~> 1.4"},                           # Core dependency - always required
    {:file_system, "~> 0.2", only: [:dev, :test]} # Optional - only in dev/test
  ]
end

def application do
  [
    extra_applications: [:logger, :jason]  # FileSystem NOT in extra_applications
  ]
end
```

### Runtime Detection Pattern

In `lib/haxe_watcher.ex`:
```elixir
# Check if FileSystem module is available at runtime
if Code.ensure_loaded?(FileSystem) do
  case FileSystem.start_link(dirs: existing_dirs) do
    {:ok, pid} ->
      FileSystem.subscribe(pid)
      {:ok, pid}
    {:error, reason} ->
      {:error, "FileSystem failed to start: #{inspect(reason)}"}
  end
else
  {:error, "FileSystem library not available. Add {:file_system, \"~> 0.2\"} to mix.exs"}
end
```

## Benefits

### 1. Reduced Core Dependencies
- **Minimal production footprint**: Production deployments don't need file watching
- **Faster installation**: Fewer dependencies to download and compile
- **Security**: Fewer dependencies means smaller attack surface

### 2. Optional Features
- **Development tools**: File watching only needed during development
- **Graceful degradation**: Library works without file watching
- **Clear separation**: Core compilation vs development conveniences

### 3. Flexible Deployment
- **Production**: Runs without `:file_system` dependency
- **Development**: Full file watching when dependency is available
- **Testing**: Can test with or without file watching

## Usage Patterns

### For Library Users

#### Basic Usage (No File Watching)
```elixir
# In your mix.exs - minimal dependencies
defp deps do
  [{:reflaxe_elixir, "~> 1.0"}]
end
```

#### Development Usage (With File Watching)
```elixir
# In your mix.exs - add file_system for watching
defp deps do
  [
    {:reflaxe_elixir, "~> 1.0"},
    {:file_system, "~> 0.2", only: [:dev, :test]}
  ]
end
```

### For Library Developers

When adding optional features:
```elixir
defmodule OptionalFeature do
  def start do
    if Code.ensure_loaded?(OptionalDependency) do
      # Use the optional dependency
      OptionalDependency.do_something()
    else
      # Provide fallback or error message
      {:error, "Feature requires OptionalDependency"}
    end
  end
end
```

## Implementation Guidelines

### 1. Always Check Availability
```elixir
# ✅ CORRECT: Check before use
if Code.ensure_loaded?(FileSystem) do
  FileSystem.start_link(...)
end

# ❌ WRONG: Direct call without checking
FileSystem.start_link(...)  # Crashes if not available
```

### 2. Provide Clear Error Messages
```elixir
# ✅ GOOD: Helpful error message
{:error, "FileSystem library not available. Add {:file_system, \"~> 0.2\"} to mix.exs"}

# ❌ BAD: Generic error
{:error, "dependency missing"}
```

### 3. Document Optional Dependencies
In your library documentation:
```markdown
## Optional Dependencies

- `:file_system` - Enables file watching for automatic recompilation
  Add to your mix.exs: `{:file_system, "~> 0.2", only: [:dev, :test]}`
```

## Trade-offs

### Advantages
- ✅ Smaller production deployments
- ✅ Faster dependency installation
- ✅ Clear separation of concerns
- ✅ No unused dependencies in production

### Disadvantages
- ⚠️ Runtime checks add minimal overhead
- ⚠️ Users must manually add dependency for full features
- ⚠️ Documentation must clearly explain optional features

## Best Practices

1. **Mark dependencies correctly**: Use `only: [:dev, :test]` for development-only features
2. **Check at runtime**: Use `Code.ensure_loaded?/1` before using optional modules
3. **Fail gracefully**: Provide helpful error messages when dependencies are missing
4. **Document clearly**: List optional dependencies and their purposes
5. **Test both paths**: Test with and without optional dependencies

## Example: HaxeWatcher Implementation

The HaxeWatcher module demonstrates the pattern perfectly:

```elixir
defmodule HaxeWatcher do
  @moduledoc """
  File watcher for automatic Haxe recompilation.
  
  ## Optional Dependencies
  
  Requires `:file_system` for file watching functionality.
  Add to your mix.exs: `{:file_system, "~> 0.2", only: [:dev, :test]}`
  """
  
  def start_link(config) do
    if Code.ensure_loaded?(FileSystem) do
      # File watching available - full functionality
      start_file_watcher(config)
    else
      # No file watching - inform user
      IO.puts("File watching not available. Add :file_system to mix.exs for auto-compilation.")
      {:ok, self()}  # Return dummy process
    end
  end
end
```

## Conclusion

The on-demand loading pattern provides flexibility and efficiency by making non-essential dependencies optional. This keeps the core library lean while still offering powerful development features when needed. The pattern is particularly valuable for development tools that aren't required in production deployments.
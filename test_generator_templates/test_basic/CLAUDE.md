# AI Development Instructions for test_basic

This file contains instructions for AI assistants (Claude, ChatGPT, etc.) working on this Reflaxe.Elixir project.

## 📋 Project Overview

- **Project**: test_basic
- **Type**: Mix Project
- **Framework**: Reflaxe.Elixir (Haxe → Elixir compilation)
- **Architecture**: Compile-time transpiler with file watching

## 🚀 Quick Start for AI Development

### 1. Start File Watcher
```bash
# Start the watcher for real-time compilation
mix compile.haxe --watch

# You'll see:
[10:30:45] Starting HaxeWatcher...
[10:30:45] Watching directories: ["src_haxe"]
[10:30:45] Ready for changes. Press Ctrl+C to stop.
```

### 2. Development Workflow
1. Edit .hx files in `src_haxe/`
2. Save file → Automatic compilation in ~100-200ms
3. Generated .ex files appear in `lib/generated/`
4. Test changes immediately - no manual compilation needed!

## ⚡ File Watching Benefits

- **Sub-second compilation**: 0.1-0.3s per file change (10-50x faster than cold compilation)
- **Immediate error feedback**: See compilation errors instantly
- **Source mapping**: Errors show Haxe source positions, not generated Elixir
- **Continuous validation**: Code always compiles before you move on






## 🔧 Mix Project Development

### Development Commands
```bash
# Terminal 1: Start watcher
mix compile.haxe --watch

# Terminal 2: Run your application
iex -S mix

# Or run specific modules
mix run -e "MyModule.main()"
```


## 🗺️ Source Mapping & Debugging

### Enable Source Mapping
Add to your `build.hxml`:
```hxml
-D source-map  # Enable source mapping for debugging
```

### Use Source Maps for Debugging
```bash
# Map Elixir error back to Haxe source
mix haxe.source_map lib/MyModule.ex 45 12
# Output: src_haxe/MyModule.hx:23:15

# Check compilation errors with source positions
mix haxe.errors --format json

# Get structured compilation status
mix haxe.status --format json
```

## 📁 Project Structure

```
test_basic/
├── src_haxe/              # 🎯 Edit Haxe files here
│   ├── Main.hx            # Entry point
│   └── 
│       └── services/      # Service modules

├── lib/                   
│   └── generated/         # ⚡ Auto-generated Elixir code
├── build.hxml             # Haxe build configuration  
├── mix.exs                # Elixir project configuration
└── CLAUDE.md              # This file
```

## ✅ Best Practices

### 1. Always Use File Watcher
- **Start watcher first**: `mix compile.haxe --watch`
- **Keep it running**: One terminal dedicated to watching
- **Check feedback**: Watch for compilation success/errors

### 2. Source Mapping for Error Fixes
- **Use precise positions**: Source maps show exact Haxe line/column
- **Query error locations**: `mix haxe.source_map <file> <line> <col>`
- **Fix at source**: Edit Haxe files, not generated Elixir

### 3. Rapid Development Loop
1. Edit .hx file and save
2. Watch compilation result (~200ms)
3. Test changes immediately
4. Fix errors using source positions
5. Repeat for fast iteration

## 🔧 Troubleshooting

### Watcher Not Starting
```bash
# Check if port 6000 is in use
lsof -i :6000

# Use different port if needed
mix compile.haxe --watch --port 6001

# Reset watcher state
rm -rf .haxe_cache && mix compile.haxe --watch --force
```

### Changes Not Detected
```bash
# Verify files are in watched directories
mix haxe.status

# Check if src_haxe/ contains .hx files
ls src_haxe/**/*.hx
```

### Compilation Errors
```bash
# Get detailed error information
mix haxe.errors --format json

# Check source mapping
mix haxe.source_map <generated_file> <line> <column>
```

## 📚 LLM-Optimized Documentation

This project includes comprehensive documentation specifically designed for AI assistants:

### Foundation Documentation (in .taskmaster/docs/llm/)
- **HAXE_FUNDAMENTALS.md** - Essential Haxe language knowledge
- **REFLAXE_ELIXIR_BASICS.md** - Core Reflaxe.Elixir concepts and patterns
- **QUICK_START_PATTERNS.md** - Copy-paste ready code patterns
- **PROJECT_SPECIFICS.md** - Template-specific guidance for this project
- **API_REFERENCE_SKELETON.md** - API documentation (grows as you code)

### Pattern Extraction (in .taskmaster/docs/patterns/)
- **PATTERNS.md** - Auto-extracted patterns from your code

### Generating Enhanced Documentation
```bash
# Generate full API documentation
npx haxe build.hxml -D generate-llm-docs

# Extract patterns from your code
npx haxe build.hxml -D extract-patterns
```

## 📚 Additional Resources

- [Watcher Development Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/WATCHER_DEVELOPMENT_GUIDE.md)
- [Source Mapping Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/SOURCE_MAPPING.md)
- [Getting Started Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/GETTING_STARTED.md)

---

**Remember**: The watcher provides sub-second compilation perfect for AI-assisted development. Always start with `mix compile.haxe --watch` for the best experience!
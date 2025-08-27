# test_llm_docs

A Mix project built with Reflaxe.Elixir

## Getting Started

### Prerequisites

- Haxe 4.3+
- Elixir 1.14+
- Node.js 16+

### Installation

```bash
# Install dependencies
npm install
mix deps.get

# Compile Haxe to Elixir
npx haxe build.hxml
```

### Development

```bash
# Watch mode (auto-compile on changes)
npm run watch

# Run tests
mix test
```



### Project Structure

```
.
├── src_haxe/          # Haxe source files



│   └── services/      # Service modules

├── lib/               # Elixir code
│   └── generated/     # Generated from Haxe
├── test/              # Tests
├── build.hxml         # Haxe build configuration
├── mix.exs            # Elixir project file
└── package.json       # Node dependencies
```





## Development Workflow

1. **Edit Haxe Files**: Make changes in `src_haxe/`
2. **Automatic Compilation**: File watcher compiles to Elixir
3. **Test Changes**: Run tests or use the application
4. **Debug with Source Maps**: Errors map back to Haxe source

### Compilation Flags

Add these to your `build.hxml` for different modes:

```hxml
# Development mode with source maps
-D source-map
-D debug

# Production mode
-D no-debug
-D analyzer-optimize

# Generate LLM documentation
-D generate-llm-docs

# Extract code patterns
-D extract-patterns
```

## Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/my_test.exs

# Run with coverage
mix test --cover
```

## Documentation

### For AI Assistants

This project includes AI-optimized documentation:
- `CLAUDE.md` - Instructions for AI assistants
- `.taskmaster/docs/llm/` - Language and framework guides
- `.taskmaster/docs/patterns/` - Extracted code patterns

### Generating Documentation

```bash
# Generate API documentation
npx haxe build.hxml -D generate-llm-docs

# Extract patterns from code
npx haxe build.hxml -D extract-patterns
```

## Learn More

- [Reflaxe.Elixir Documentation](https://github.com/fullofcaffeine/reflaxe.elixir)
- [Haxe Documentation](https://haxe.org)
- [Elixir Documentation](https://elixir-lang.org)


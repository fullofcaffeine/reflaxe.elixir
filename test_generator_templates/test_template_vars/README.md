# test_template_vars

A Phoenix web application built with Reflaxe.Elixir

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


### Running the Phoenix Server

```bash
# Start Phoenix with file watching
iex -S mix phx.server

# Visit http://localhost:4000
```

The server will automatically recompile Haxe files and reload the browser when you make changes.


### Project Structure

```
.
├── src_haxe/          # Haxe source files

│   ├── controllers/   # Phoenix controllers
│   ├── live/          # LiveView components
│   ├── schemas/       # Ecto schemas
│   └── views/         # Phoenix views


│   ├── live/          # LiveView components
│   ├── schemas/       # Ecto schemas
│   └── services/      # Business logic


├── lib/               # Elixir code
│   └── generated/     # Generated from Haxe
├── test/              # Tests
├── build.hxml         # Haxe build configuration
├── mix.exs            # Elixir project file
└── package.json       # Node dependencies
```


## Phoenix Features

This project includes:
- Phoenix web framework integration
- LiveView for real-time features
- Ecto for database operations
- HEEx templates via HXX processing

### Key Phoenix Files

- `src_haxe/router/Router.hx` - Phoenix router configuration
- `src_haxe/controllers/` - HTTP request handlers
- `src_haxe/live/` - LiveView components
- `src_haxe/schemas/` - Database schemas



## LiveView Features

This project is built with Phoenix LiveView for real-time user interfaces:
- Server-rendered HTML with real-time updates
- No JavaScript framework required
- Full-stack type safety with Haxe

### Key LiveView Components

- `src_haxe/live/` - LiveView modules
- Real-time event handling
- WebSocket-based updates
- Stateful server components


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

- [Phoenix Framework](https://phoenixframework.org)


- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)

# Project Generator Guide

Complete guide to using the Reflaxe.Elixir project generator to bootstrap new projects.

## Table of Contents

1. [Installation](#installation)
2. [Using the Generator](#using-the-generator)
3. [Project Types](#project-types)
4. [What Gets Generated](#what-gets-generated)
5. [Post-Generation Workflow](#post-generation-workflow)
6. [Development Tools](#development-tools)
7. [Customization](#customization)
8. [Troubleshooting](#troubleshooting)

## Installation

### Prerequisites

Before using the generator, ensure you have:
- **Node.js 16+** (for lix package manager)
- **Elixir 1.14+** (for running generated code)
- **Git** (for installing from GitHub)

### Installing Reflaxe.Elixir

#### Option 1: Using lix (Recommended)

```bash
# Install lix if you haven't already
npm install -g lix

# Install Reflaxe.Elixir from GitHub
npx lix install github:fullofcaffeine/reflaxe.elixir
```

#### Option 2: Using haxelib

```bash
# Install from haxelib repository
haxelib install reflaxe.elixir

# Or install from GitHub
haxelib git reflaxe.elixir https://github.com/fullofcaffeine/reflaxe.elixir
```

### Verifying Installation

```bash
# With lix
npx lix run reflaxe.elixir help

# With haxelib
haxelib run reflaxe.elixir help
```

You should see the generator help message with available commands.

## Using the Generator

### Basic Usage

```bash
# Create a new project with interactive prompts
npx lix run reflaxe.elixir create my-app

# Or with haxelib
haxelib run reflaxe.elixir create my-app
```

### Command-Line Options

```bash
# Skip interactive prompts
npx lix run reflaxe.elixir create my-app --no-interactive

# Specify project type
npx lix run reflaxe.elixir create my-app --type phoenix

# Skip dependency installation
npx lix run reflaxe.elixir create my-app --skip-install

# Verbose output for debugging
npx lix run reflaxe.elixir create my-app --verbose
```

### Interactive Mode

When you run the generator without options, it will prompt you for:

1. **Project name** - Name of your project (default: my-app)
2. **Project type** - Basic, Phoenix, LiveView, or add-to-existing
3. **Database** (Phoenix only) - PostgreSQL, MySQL, SQLite, or none
4. **Authentication** (LiveView only) - Include auth system?
5. **Example modules** - Include example code?
6. **Install dependencies** - Install npm/mix deps now?

### All Available Options

| Option | Description | Values |
|--------|-------------|--------|
| `--type` | Project type | basic, phoenix, liveview, add-to-existing |
| `--no-interactive` | Skip prompts | - |
| `--skip-install` | Don't install dependencies | - |
| `--verbose` | Show detailed output | - |
| `--help` | Show help message | - |

## Project Types

### Basic Project

Standard Mix project with utilities and services.

```bash
npx lix run reflaxe.elixir create my-app --type basic
```

**Includes:**
- Mix project structure
- Utility modules (StringUtils, MathHelper)
- Service modules (UserService)
- Basic configuration
- Test setup
- CLAUDE.md with AI development instructions

**Use when:** Building libraries, CLI tools, or simple services.

### Phoenix Project

Full Phoenix web application.

```bash
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
```

**Includes:**
- Phoenix application structure
- Router configuration
- Controller examples
- Ecto setup
- Asset pipeline
- Test helpers
- CLAUDE.md with Phoenix-specific AI development instructions

**Use when:** Building web applications, APIs, or microservices.

### LiveView Project

Phoenix with LiveView for interactive UIs.

```bash
npx lix run reflaxe.elixir create my-liveview-app --type liveview
```

**Includes:**
- Everything from Phoenix
- LiveView components
- Real-time features
- WebSocket configuration
- Interactive examples
- Optional authentication
- CLAUDE.md with LiveView-specific AI development instructions

**Use when:** Building interactive web applications with real-time features.

### Add to Existing

Add Reflaxe.Elixir to an existing Elixir project.

```bash
cd existing-project
npx lix run reflaxe.elixir create --type add-to-existing
```

**Includes:**
- src_haxe/ directory
- build.hxml configuration
- package.json with scripts
- Mix compiler integration
- Example module
- CLAUDE.md with AI development instructions

**Use when:** Gradually migrating existing Elixir code to Haxe.

## What Gets Generated

### Directory Structure

```
my-app/
├── src_haxe/              # Haxe source files
│   ├── Main.hx            # Entry point
│   ├── utils/             # Utility modules
│   │   ├── StringUtils.hx
│   │   └── MathHelper.hx
│   ├── services/          # Business logic
│   │   └── UserService.hx
│   └── live/              # LiveView components (if applicable)
│       └── AppLive.hx
├── lib/                   # Elixir code
│   ├── generated/         # Generated from Haxe
│   └── my_app/            # Manual Elixir code
├── test/                  # Tests
│   ├── haxe/              # Haxe tests
│   └── elixir/            # ExUnit tests
├── .vscode/               # VS Code configuration
│   ├── settings.json      # Editor settings
│   ├── extensions.json    # Recommended extensions
│   └── launch.json        # Debug configuration
├── build.hxml             # Haxe build configuration
├── mix.exs                # Elixir project file
├── package.json           # Node dependencies
├── README.md              # Project documentation
├── CLAUDE.md              # AI development instructions
└── .gitignore            # Git ignore rules
```

### Configuration Files

#### build.hxml
```hxml
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe.output=lib/generated
-D reflaxe_runtime
--main Main
```

#### package.json
```json
{
  "name": "my-app",
  "version": "0.1.0",
  "scripts": {
    "compile": "npx haxe build.hxml",
    "watch": "npx nodemon --watch src_haxe --ext hx --exec \"npx haxe build.hxml\"",
    "test": "npm run test:haxe && npm run test:elixir",
    "test:haxe": "npx haxe test.hxml",
    "test:elixir": "mix test"
  },
  "devDependencies": {
    "lix": "^15.12.4",
    "nodemon": "^3.0.0"
  }
}
```

#### mix.exs (additions for existing projects)
```elixir
def project do
  [
    # ... existing config ...
    compilers: [:haxe] ++ Mix.compilers(),
    # ... rest of config ...
  ]
end
```

### VS Code Integration

#### settings.json
```json
{
  "editor.formatOnSave": true,
  "files.exclude": {
    "**/_build": true,
    "**/deps": true,
    "**/node_modules": true
  },
  "[haxe]": {
    "editor.insertSpaces": false
  },
  "[elixir]": {
    "editor.insertSpaces": true,
    "editor.tabSize": 2
  }
}
```

#### extensions.json
```json
{
  "recommendations": [
    "vshaxe.haxe-extension-pack",
    "jakebecker.elixir-ls",
    "phoenixframework.phoenix"
  ]
}
```

#### CLAUDE.md
```markdown
# AI Development Instructions for my-app

This file contains instructions for AI assistants (Claude, ChatGPT, etc.) working on this Reflaxe.Elixir project.

## 🚀 Quick Start for AI Development

### 1. Start File Watcher
```bash
# Start the watcher for real-time compilation
mix compile.haxe --watch
```

### 2. Development Workflow
1. Edit .hx files in `src_haxe/`
2. Save file → Automatic compilation in ~100-200ms
3. Generated .ex files appear in `lib/generated/`
4. Test changes immediately - no manual compilation needed!

# ... (continues with project-specific watcher instructions)
```

## Post-Generation Workflow

### 1. Navigate to Project

```bash
cd my-app
```

### 2. Install Dependencies (if skipped)

```bash
# Install Node dependencies
npm install

# Install Elixir dependencies
mix deps.get

# For Phoenix projects, also run:
mix ecto.create
```

### 3. Write Your First Module

Create `src_haxe/Greeter.hx`:

```haxe
package;

@:module
class Greeter {
    public static function greet(name: String): String {
        return 'Hello, $name! Welcome to Reflaxe.Elixir!';
    }
    
    public static function main(): Void {
        var message = greet("World");
        trace(message);
    }
}
```

### 4. Compile to Elixir

```bash
npm run compile

# Or directly:
npx haxe build.hxml
```

This generates `lib/generated/Greeter.ex`:

```elixir
defmodule Greeter do
  def greet(name) do
    "Hello, #{name}! Welcome to Reflaxe.Elixir!"
  end
  
  def main() do
    message = greet("World")
    IO.inspect(message)
  end
end
```

### 5. Run Your Code

```bash
# Run directly
mix run -e "Greeter.main()"

# Or start interactive shell
iex -S mix
iex> Greeter.greet("Haxe")
"Hello, Haxe! Welcome to Reflaxe.Elixir!"

# For Phoenix projects
mix phx.server
# Visit http://localhost:4000
```

## Development Tools

### Watch Mode

Automatically recompile on file changes:

```bash
npm run watch
```

### Testing

```bash
# Run all tests
npm test

# Run only Haxe tests
npm run test:haxe

# Run only Elixir tests
npm run test:elixir
mix test
```

### Debugging

1. **VS Code Debugging**
   - Press F5 to start debugging
   - Set breakpoints in generated Elixir code
   - Step through execution

2. **IEx Debugging**
   ```elixir
   # Add breakpoint in code
   require IEx
   IEx.pry()
   
   # Run with:
   iex -S mix
   ```

3. **Trace Output**
   ```haxe
   // In Haxe
   trace("Debug message", someVariable);
   ```
   Compiles to:
   ```elixir
   # In Elixir
   IO.inspect("Debug message")
   IO.inspect(some_variable)
   ```

### Hot Reload (Phoenix)

For Phoenix projects, hot reload is automatic:

1. Haxe files compile to Elixir on save (with watch mode)
2. Phoenix reloads changed Elixir files
3. Browser auto-refreshes with LiveReload

### Production Build

```bash
# Compile with optimizations
npx haxe build.hxml -D release

# For Phoenix
MIX_ENV=prod mix compile
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

## Customization

### Adding Libraries

#### Haxe Libraries

```bash
# Using lix
npx lix install haxelib:tink_core
npx lix install github:haxetink/tink_json

# Using haxelib
haxelib install tink_core
```

Add to build.hxml:
```hxml
-lib tink_core
-lib tink_json
```

#### Elixir Libraries

Add to mix.exs:
```elixir
defp deps do
  [
    {:phoenix, "~> 1.7.0"},
    {:ecto, "~> 3.10"},
    {:jason, "~> 1.4"},
    # Add your dependencies here
  ]
end
```

Then run:
```bash
mix deps.get
```

### Project Templates

Create custom templates in `.templates/`:

```
.templates/
├── module.hx.template
├── liveview.hx.template
└── test.hx.template
```

### Build Configurations

Create multiple build configurations:

```hxml
# build-dev.hxml
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe.output=lib/generated
-D dev
--main Main

# build-prod.hxml
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe.output=lib/generated
-D release
-D no-traces
--main Main
```

## Troubleshooting

### Common Issues

#### "Command not found: lix"

```bash
# Install lix globally
npm install -g lix

# Or use npx
npx lix run reflaxe.elixir create my-app
```

#### "Module reflaxe.elixir not found"

```bash
# Reinstall Reflaxe.Elixir
npx lix reinstall reflaxe.elixir

# Or with haxelib
haxelib remove reflaxe.elixir
haxelib install reflaxe.elixir
```

#### "Type not found" errors

Make sure you have the latest version:
```bash
npx lix install github:fullofcaffeine/reflaxe.elixir --force
```

#### Phoenix won't start

```bash
# Ensure database is created
mix ecto.create
mix ecto.migrate

# Check for port conflicts
lsof -i :4000

# Start with verbose output
mix phx.server
```

#### Generated code has errors

1. Check Haxe syntax is valid
2. Ensure annotations are correct
3. Verify type mappings
4. Check CLAUDE.md for known issues

### Getting Help

1. **Documentation**: Check other guides in `documentation/`
2. **Examples**: Review `examples/` directory
3. **Issues**: Report at GitHub Issues
4. **Community**: Join Discord/Slack for support

## Next Steps

Now that you have a generated project:

1. Read [TUTORIAL_FIRST_PROJECT.md](./TUTORIAL_FIRST_PROJECT.md) for a step-by-step tutorial
2. Explore [EXAMPLES_GUIDE.md](./EXAMPLES_GUIDE.md) for patterns
3. Check [USER_GUIDE.md](./USER_GUIDE.md) for feature reference
4. See [DEVELOPMENT_WORKFLOW.md](./DEVELOPMENT_WORKFLOW.md) for productivity tips

Happy coding with Reflaxe.Elixir! 🚀
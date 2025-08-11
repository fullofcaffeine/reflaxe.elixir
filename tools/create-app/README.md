# Create Reflaxe Elixir App

The official generator for creating Reflaxe.Elixir projects.

## Usage

There are several ways to use this generator:

### Method 1: Using npx (Recommended)

No installation needed, just run:

```bash
npx @reflaxe/create-elixir-app my-app
```

Or for Phoenix projects:

```bash
npx @reflaxe/create-elixir-app my-phoenix-app --phoenix
```

### Method 2: Global Installation

Install globally and use anywhere:

```bash
npm install -g @reflaxe/create-elixir-app
create-reflaxe-elixir my-app
```

### Method 3: From the Monorepo (Development)

If you're working with the haxe.elixir monorepo:

```bash
# From the monorepo root
node tools/create-app/index.js my-app

# Or install locally
cd tools/create-app
npm link
create-reflaxe-elixir my-app
```

## Options

```bash
create-reflaxe-elixir [project-name] [options]

Options:
  --phoenix             Create a Phoenix project with LiveView
  --basic               Create a basic project (default)
  --add-to-existing    Add to an existing Elixir project
  --skip-install       Skip dependency installation
  --verbose            Verbose output
  -V, --version        Output version number
  -h, --help          Display help
```

## Project Types

### Basic Project
Standard Haxe→Elixir project with utility modules and services:
```bash
npx @reflaxe/create-elixir-app my-app --basic
```

Creates:
- Utility modules (StringUtils, etc.)
- Service modules (UserService, etc.)
- Mix integration
- VS Code configuration

### Phoenix Project
Full Phoenix application with LiveView support:
```bash
npx @reflaxe/create-elixir-app my-app --phoenix
```

Creates:
- Phoenix application structure
- LiveView components
- Ecto schemas and migrations
- Router configuration
- Full Phoenix integration

### Add to Existing
Add Reflaxe.Elixir to an existing Elixir/Phoenix project:
```bash
cd existing-project
npx @reflaxe/create-elixir-app --add-to-existing
```

Adds:
- src_haxe/ directory
- build.hxml configuration
- Mix compiler task
- Package.json with scripts

## Generated Project Structure

```
my-app/
├── src_haxe/              # Haxe source files
│   ├── utils/             # Utility modules
│   ├── services/          # Business logic
│   ├── live/              # LiveView components (Phoenix)
│   └── schemas/           # Ecto schemas (Phoenix)
├── lib/                   # Elixir code (generated + custom)
│   ├── generated/         # Generated from Haxe
│   └── mix/tasks/         # Mix tasks
├── test/                  # Tests
├── .vscode/               # VS Code configuration
│   ├── settings.json      # Editor settings
│   └── extensions.json    # Recommended extensions
├── build.hxml             # Haxe build configuration
├── mix.exs                # Elixir project file
├── package.json           # Node dependencies
└── README.md              # Project documentation
```

## What Gets Installed

### NPM Dependencies
- `reflaxe` - Core Reflaxe framework
- `reflaxe-elixir` - Elixir target for Reflaxe  
- `nodemon` - File watcher for development

### Mix Dependencies (Phoenix projects)
- `phoenix` - Web framework
- `phoenix_live_view` - LiveView
- `ecto` - Database wrapper
- `phoenix_ecto` - Phoenix/Ecto integration

### VS Code Extensions
- Haxe language support
- Elixir language support
- Bracket pair colorizer
- Auto rename tag

## Development Workflow

After creating your project:

```bash
cd my-app

# Install dependencies
npm install
mix deps.get

# Compile Haxe to Elixir
npm run compile

# Watch mode (auto-compile)
npm run watch

# Run tests
npm test

# Start Phoenix server (Phoenix projects)
mix phx.server
```

## Publishing

This generator is published to npm as part of the Reflaxe.Elixir release process:

```bash
# From tools/create-app directory
npm publish
```

Users can then use it immediately via npx without installation.

## Local Development

To test the generator locally during development:

```bash
# From monorepo root
cd tools/create-app
npm link

# Now you can use it globally
create-reflaxe-elixir test-app

# Or test directly
node index.js test-app --verbose
```

## Integration with Monorepo

This generator is part of the haxe.elixir monorepo and:
- Uses examples from `examples/` as templates
- Shares documentation with main project
- Published independently to npm for easy usage
- Maintained alongside the compiler

## License

MIT - Same as the haxe.elixir project
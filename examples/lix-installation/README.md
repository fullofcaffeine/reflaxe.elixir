# Lix Installation Example

This example demonstrates how to install and use Reflaxe.Elixir via Lix in a new project.

## Setup

```bash
# 1. Initialize a new Haxe project with Lix
mkdir my-elixir-project
cd my-elixir-project
npm init -y
npm install lix

# 2. Install Reflaxe.Elixir from GitHub
npx lix install github:fullofcaffeine/reflaxe.elixir

# 3. (Optional) Install a specific version
# npx lix install github:fullofcaffeine/reflaxe.elixir#v1.0.5

# 4. Use the scope (makes dependencies available)
npx lix use
```

## Project Structure

```
my-elixir-project/
├── package.json
├── build.hxml          # Haxe build configuration
├── src_haxe/          # Your Haxe source files
│   └── Main.hx
└── lib/               # Generated Elixir files (output)
```

## Usage

1. Create your Haxe source file:

```haxe
// src_haxe/Main.hx
class Main {
    public static function main() {
        trace("Hello from Haxe to Elixir!");
    }
}
```

2. Create build configuration:

```hxml
# build.hxml
-lib reflaxe.elixir
-cp src_haxe
-D elixir_output=lib
-D reflaxe_runtime
Main
```

3. Compile:

```bash
haxe build.hxml
```

This will generate Elixir files in the `lib/` directory that you can use in your Elixir/Phoenix projects.

## Integration with Phoenix

To use the generated Elixir modules in a Phoenix project:

```bash
# 1. Create a Phoenix project
mix phx.new my_phoenix_app --no-ecto
cd my_phoenix_app

# 2. Copy your Haxe compilation setup
mkdir src_haxe
# Copy your Haxe files to src_haxe/

# 3. Add Haxe compilation to your Mix project
# Add to mix.exs dependencies:
# {:reflaxe_elixir, path: "path/to/reflaxe-elixir", only: [:dev]}

# 4. Compile Haxe as part of your build process
mix compile.haxe
```

## Troubleshooting

### "Library reflaxe.elixir is not installed"

Make sure you've run `npx lix use` in your project directory after installing.

### "Module not found"

Ensure your `-lib reflaxe.elixir` directive is present in your .hxml file.

### Updating to a new version

```bash
# Update to latest version
npx lix install github:fullofcaffeine/reflaxe.elixir --force

# Or update to a specific version
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.0.5 --force
```

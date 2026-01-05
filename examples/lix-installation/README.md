# Lix Installation Example

This example demonstrates how to install and use Reflaxe.Elixir via Lix in a new project.

## Setup

```bash
# 1. Initialize a new project with lix
mkdir my-elixir-project
cd my-elixir-project
npm init -y
npm install --save-dev lix
npx lix scope create

# 2. Install Reflaxe.Elixir from a GitHub release tag (recommended)
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.5

# 3. Download pinned Haxe libraries for the project
npx lix download

# 4. Verify the Haxe toolchain
npx haxe --version
```

## Project Structure

```
my-elixir-project/
├── package.json
├── .haxerc             # Haxe toolchain pin (written by lix)
├── haxe_libraries/      # lix-managed Haxe libraries
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
# Use the lix-managed Haxe wrapper (recommended)
npx haxe build.hxml
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

Make sure you installed the library and downloaded dependencies:

```bash
npx lix scope create
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.5
npx lix download
```

### "Module not found"

Ensure your `-lib reflaxe.elixir` directive is present in your .hxml file.

### Updating to a new version

```bash
# Update to a newer tag (recommended)
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.5 --force

# Or install from main (bleeding edge; not necessarily a release)
# npx lix install github:fullofcaffeine/reflaxe.elixir --force
```

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

# 2. Install the Reflaxe-built package from a GitHub release (recommended)
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"

# 3. Download pinned Haxe libraries for the project
npx lix download

# 4. Verify the Haxe toolchain
./node_modules/.bin/haxe --version
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
Main
```

3. Compile:

```bash
# Use the lix-managed Haxe shim (recommended)
./node_modules/.bin/haxe build.hxml
```

This will generate Elixir files in the `lib/` directory that you can use in your Elixir/Phoenix projects.

Haxe -> generated Elixir shape:

```haxe
class Main {
  public static function main() {
    trace("Hello from Haxe to Elixir!");
  }
}
```

```elixir
defmodule Main do
  def main do
    IO.inspect("Hello from Haxe to Elixir!")
  end
end
```

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
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"
npx lix download
```

### "Module not found"

Ensure your `-lib reflaxe.elixir` directive is present in your .hxml file.

### Updating to a new version

```bash
# Update to a newer tag (recommended)
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip" --force
```

Raw GitHub branches and tags are source checkouts, not Reflaxe-built packages. For compiler
development, follow the source-checkout helper workflow in the repository README instead of
installing `main` as a normal consumer dependency.

# 5-Minute Quickstart Guide

Get a Reflaxe.Elixir project running in under 5 minutes!

## 🚀 Installation & Project Creation

```bash
# Install Reflaxe.Elixir
npx lix install github:YourOrg/reflaxe.elixir

# Create your first project
npx lix run reflaxe.elixir create hello-world

# Navigate to your project
cd hello-world
```

## 📁 What Was Created?

```
hello-world/
├── src_haxe/          # Your Haxe source files go here
│   └── Main.hx        # Entry point
├── lib/               # Elixir output
│   └── generated/     # Compiled Haxe→Elixir files
├── build.hxml         # Haxe build configuration
├── mix.exs            # Elixir project file
└── package.json       # Node.js dependencies
```

## ✏️ Write Your First Haxe Code

Edit `src_haxe/Main.hx`:

```haxe
package;

@:module
class Main {
    public static function main(): Void {
        trace("Hello from Haxe→Elixir!");
        
        var greeting = Greeter.greet("World");
        trace(greeting);
    }
}

@:module
class Greeter {
    public static function greet(name: String): String {
        return 'Hello, $name! Welcome to Reflaxe.Elixir!';
    }
}
```

## 🔨 Compile & Run

```bash
# Compile Haxe to Elixir
npx haxe build.hxml

# Run the generated Elixir code
mix run -e "Main.main()"
```

Expected output:
```
Hello from Haxe→Elixir!
Hello, World! Welcome to Reflaxe.Elixir!
```

## 🎯 Try Different Project Types

### Phoenix Web Application
```bash
npx lix run reflaxe.elixir create my-phoenix-app --type phoenix
cd my-phoenix-app
npm install && mix deps.get
npx haxe build.hxml
mix phx.server
# Visit http://localhost:4000
```

### LiveView Interactive App
```bash
npx lix run reflaxe.elixir create my-liveview-app --type liveview
cd my-liveview-app
npm install && mix deps.get
npx haxe build.hxml
mix phx.server
# Visit http://localhost:4000
```

### Add to Existing Elixir Project
```bash
cd existing-elixir-project
npx lix run reflaxe.elixir create --type add-to-existing
# Follow the prompts to add Haxe support
```

## 💡 Development Workflow

### Watch Mode (Auto-compile on changes)
```bash
npm run watch
```

### Run Tests
```bash
# Haxe tests
npm test

# Elixir tests  
mix test
```

### Interactive Development
```bash
# Start IEx with your compiled modules
iex -S mix

# In IEx, call your Haxe-compiled functions
iex> Greeter.greet("Haxe")
"Hello, Haxe! Welcome to Reflaxe.Elixir!"
```

## 🎨 VS Code Integration

The generator automatically creates VS Code configuration. Just open the project:

```bash
code .
```

Recommended extensions will be suggested automatically:
- Haxe language support
- Elixir language support
- LiveView snippets

## 📚 Next Steps

Now that you have a working project:

1. **Explore Examples**: Check the `examples/` folder in the Reflaxe.Elixir repo
2. **Read the Guide**: See [GETTING_STARTED.md](./GETTING_STARTED.md) for detailed information
3. **Learn Features**: Review [FEATURES.md](./FEATURES.md) for available functionality
4. **Join Community**: Get help and share your projects

## 🆘 Troubleshooting

### "Command not found: lix"
```bash
npm install -g lix
```

### "Module reflaxe.elixir not found"
```bash
npx lix install github:YourOrg/reflaxe.elixir
```

### "Type not found" errors
Make sure you have the latest version:
```bash
npx lix reinstall reflaxe.elixir
```

### Phoenix won't start
```bash
mix deps.get
mix ecto.create
mix phx.server
```

## 🎉 Success!

You now have a working Haxe→Elixir project! Start building with:
- **Type safety** from Haxe
- **Power** of Elixir/BEAM
- **Productivity** of Phoenix

Happy coding! 🚀
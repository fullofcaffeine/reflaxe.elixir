# Reflaxe.Elixir Examples

This directory contains comprehensive examples demonstrating practical usage patterns, migration strategies, and best practices for Reflaxe.Elixir.

## 📁 Example Projects

### 1. [Basic Phoenix Integration](./basic-phoenix/)
**Difficulty**: Beginner  
**Features**: @:module syntax, basic Phoenix controller, simple templates  
**Use Case**: Getting started with Reflaxe.Elixir in a new Phoenix project

### 2. [User Management System](./user-management/)  
**Difficulty**: Intermediate  
**Features**: CRUD operations, LiveView, HXX templates, Ecto integration  
**Use Case**: Typical Phoenix application with user authentication

### 3. [Real-time Chat Application](./realtime-chat/)
**Difficulty**: Advanced  
**Features**: LiveView, PubSub, channels, complex state management  
**Use Case**: Real-time features with Phoenix Channels and LiveView

### 4. [E-commerce Platform](./ecommerce/)
**Difficulty**: Advanced  
**Features**: Complex business logic, payment integration, inventory management  
**Use Case**: Large-scale Phoenix application with multiple contexts

### 5. [Migration Examples](./migration/)
**Difficulty**: Varies  
**Features**: Step-by-step migration from existing Elixir code  
**Use Case**: Gradual adoption in existing Phoenix applications

## 🚀 Quick Start

Choose an example based on your experience level and use case:

### For Beginners
Start with [Basic Phoenix Integration](./basic-phoenix/):
```bash
cd examples/basic-phoenix
mix deps.get
mix compile
mix phx.server
```

### For Migration
Check out [Migration Examples](./migration/):
```bash
cd examples/migration
# Follow step-by-step guides for different migration scenarios
```

### For Advanced Features  
Try [Real-time Chat](./realtime-chat/):
```bash
cd examples/realtime-chat
mix deps.get
mix ecto.create && mix ecto.migrate
mix phx.server
```

## 📚 Learning Path

1. **Start**: Basic Phoenix Integration
2. **Practice**: User Management System  
3. **Apply**: Choose between Chat or E-commerce based on your needs
4. **Migrate**: Use Migration Examples for existing projects

## 🧪 Running Examples

Each example includes:
- Complete Phoenix application
- Comprehensive test suite
- Performance benchmarks
- Documentation and README

```bash
# Standard commands for all examples
mix deps.get          # Install dependencies
mix compile           # Compile Haxe and Elixir code
mix test              # Run test suite
mix phx.server        # Start development server (if Phoenix app)

# Additional commands
haxe test/integration/CompilationTest.hxml  # Run Haxe integration tests
haxe test/performance/Benchmarks.hxml      # Run performance benchmarks
```

## 📖 Example Documentation

Each example contains:
- **README.md** - Overview and setup instructions
- **ARCHITECTURE.md** - Code organization and patterns
- **MIGRATION.md** - If applicable, migration notes
- **PERFORMANCE.md** - Performance characteristics and benchmarks

## 🤝 Contributing

Want to add an example? Please:
1. Follow the [Example Template](./template/)
2. Include comprehensive documentation
3. Add integration tests
4. Submit a pull request

---

**Next Steps**: Choose an example that matches your needs and dive into the code!
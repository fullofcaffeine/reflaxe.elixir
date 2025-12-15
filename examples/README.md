# Reflaxe.Elixir Examples

This directory contains progressive examples demonstrating Haxe→Elixir compilation using Reflaxe.Elixir.

## 📁 Example Projects

### 1. [01-simple-modules](./01-simple-modules/)
**Difficulty**: Beginner  
**Features**: Basic module compilation, type mapping, simple functions  
**Use Case**: Getting started with Reflaxe.Elixir basics

### 2. [02-mix-project](./02-mix-project/)  
**Difficulty**: Beginner  
**Features**: Mix integration, multiple modules, ExUnit testing  
**Use Case**: Understanding Mix build pipeline integration

### 3. [03-phoenix-app](./03-phoenix-app/)
**Difficulty**: Intermediate  
**Features**: Phoenix endpoint/router/controller authored in Haxe, JSON responses  
**Use Case**: Minimal Phoenix web app with Haxe→Elixir compilation

### 4. [04-ecto-migrations](./04-ecto-migrations/)
**Difficulty**: Intermediate  
**Features**: @:migration annotation, database schemas, foreign keys  
**Use Case**: Database migration management with type safety

### 5. [05-heex-templates](./05-heex-templates/)
**Difficulty**: Intermediate  
**Features**: @:template annotation, HEEx syntax, form components  
**Use Case**: Type-safe Phoenix templates and components

### 6. [06-user-management](./06-user-management/)
**Difficulty**: Advanced  
**Features**: Complete CRUD, LiveView, GenServer, Ecto schemas, changesets  
**Use Case**: Full-featured Phoenix application example

### 7. [07-protocols](./07-protocols/)
**Difficulty**: Intermediate  
**Features**: @:protocol, @:impl annotations, polymorphic dispatch  
**Use Case**: Type-safe polymorphic behavior with compile-time validation

### 8. [08-behaviors](./08-behaviors/)
**Difficulty**: Advanced  
**Features**: @:behaviour, @:use annotations, callback contracts, GenServer integration  
**Use Case**: Compile-time behavior contracts with OTP integration and optional callbacks

### 9. [09-phoenix-router](./09-phoenix-router/)
**Difficulty**: Intermediate  
**Features**: Router DSL, route helpers, LiveDashboard routing  
**Use Case**: Type-safe Phoenix routing from Haxe

### 10. [10-option-patterns](./10-option-patterns/)
**Difficulty**: Intermediate  
**Features**: Option patterns and ergonomics  
**Use Case**: Practical Option usage on the Elixir target

### 11. [11-domain-validation](./11-domain-validation/)
**Difficulty**: Advanced  
**Features**: Domain validation patterns, typed constraints  
**Use Case**: Modeling rich domain logic in Haxe for the BEAM

### 12. [todo-app](./todo-app/)
**Difficulty**: Advanced  
**Features**: Full Phoenix LiveView app, Ecto, Playwright E2E  
**Use Case**: End-to-end reference app (recommended for Phoenix/LiveView)

### 13. [test-integration](./test-integration/)
**Difficulty**: Intermediate  
**Features**: Mix compiler task testing, build pipeline validation  
**Use Case**: Testing Haxe→Elixir compilation in Mix projects

## 🚀 Quick Start

Choose an example based on your experience level:

### For Beginners
Start with [01-simple-modules](./01-simple-modules/):
```bash
cd examples/01-simple-modules
haxe compile-all.hxml
```

### For Mix Integration
Try [02-mix-project](./02-mix-project/):
```bash
cd examples/02-mix-project
mix deps.get
mix compile
mix test
```

### For Phoenix Development  
Explore [03-phoenix-app](./03-phoenix-app/):
```bash
cd examples/03-phoenix-app
mix deps.get
mix compile
mix phx.server
```

## 📚 Learning Path

1. **Start**: 01-simple-modules - Basic compilation
2. **Learn**: 02-mix-project - Mix integration  
3. **Build**: 03-phoenix-app - Phoenix LiveView
4. **Extend**: 04-ecto-migrations, 05-heex-templates
5. **Master**: 06-user-management - Everything integrated

## 🧪 Running Examples

Each example can be compiled independently:

```bash
# For simple Haxe compilation
haxe build.hxml

# For Mix-integrated projects  
mix deps.get
mix compile
mix test
mix phx.server  # If Phoenix app
```

### Automated Testing

All examples are automatically tested for compilation health:

```bash
# Test all 8 examples at once
npm run test:examples

# Run comprehensive test suite (includes examples)  
npm test

# Validate specific example
cd examples/[example-name]
haxe build.hxml
```

### Continuous Integration

Examples are tested in CI/CD on every commit to ensure:
- ✅ All 9 examples compile successfully
- ✅ Generated Elixir code is syntactically valid
- ✅ No compilation warnings or errors
- ✅ Documentation consistency maintained
- ✅ Build configurations are correct

## 📖 Common Patterns

### Annotations
- `@:schema` - Define Ecto schemas
- `@:changeset` - Create changeset functions  
- `@:liveview` - Generate Phoenix LiveView modules
- `@:genserver` - Create OTP GenServer modules
- `@:migration` - Define database migrations
- `@:template` - Compile HEEx templates
- `@:query` - Build type-safe Ecto queries

### Compilation
All examples use project lix dependencies:
```hxml
-lib reflaxe.elixir
-lib reflaxe
-D reflaxe_runtime
```

## 🛠 Requirements

- **Haxe**: 4.3.6+ (managed by lix, no global install needed)
- **Elixir**: 1.14+
- **Phoenix**: 1.7+ (for Phoenix examples)
- **PostgreSQL**: For Ecto examples

## 💡 Development Workflow

1. **Edit** Haxe source in `src_haxe/` directories
2. **Compile** with `haxe build.hxml`  
3. **Generated** Elixir appears in `lib/` directories
4. **Test** with standard Elixir/Phoenix tools

---

**Next Steps**: Start with [01-simple-modules](./01-simple-modules/) and work your way through the examples!

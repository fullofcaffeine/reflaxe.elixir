# Reflaxe.Elixir Examples Guide

This guide provides walkthroughs for all example projects, showing how to use Reflaxe.Elixir features in practice.

## ✅ Working Examples

### 01-simple-modules
**Status**: Production Ready  
**Purpose**: Basic compilation patterns and module generation

**Key Features Demonstrated**:
- Basic Haxe to Elixir compilation
- Module structure generation
- Function compilation
- Simple type mapping

**How to Run**:
```bash
cd examples/01-simple-modules
npx haxe compile-all.hxml
```

**Files Generated**:
- `BasicModule.ex` - Simple module structure
- `MathHelper.ex` - Mathematical utility functions
- `UserUtil.ex` - User management utilities

### 02-mix-project
**Status**: Production Ready  
**Purpose**: Complete Mix project integration with utilities

**Key Features Demonstrated**:
- Mix project integration
- Multiple utility modules
- Package resolution
- Cross-module dependencies

**Modules Included**:
- `utils.StringUtils` - String processing utilities
- `utils.MathHelper` - Mathematical operations and validation
- `utils.ValidationHelper` - Input validation and sanitization
- `services.UserService` - Business logic and user management

**How to Run**:
```bash
cd examples/02-mix-project
npx haxe build.hxml
mix test
```

### 03-phoenix-app
**Status**: Production Ready  
**Purpose**: Phoenix application structure generation

**Key Features Demonstrated**:
- Phoenix application module compilation
- Application startup configuration
- Phoenix framework integration

**How to Run**:
```bash
cd examples/03-phoenix-app
npx haxe build.hxml
```

### 04-ecto-migrations
**Status**: Production Ready  
**Purpose**: Real migration DSL with table operations

**Key Features Demonstrated**:
- @:migration annotation usage
- Real DSL helper functions (createTable, addColumn, addIndex, addForeignKey)
- TableBuilder fluent interface
- Migration rollback support

**Migration Examples**:
- `CreateUsers.hx` - Basic table creation with indexes
- `CreatePosts.hx` - Advanced migration with foreign keys and constraints

**Generated DSL Example**:
```elixir
create table(:users) do
  add :id, :serial, primary_key: true
  add :name, :string, null: false
  add :email, :string, null: false
  add :age, :integer
  timestamps()
end

create unique_index(:users, [:email])
```

**How to Run**:
```bash
cd examples/04-ecto-migrations
npx haxe build.hxml
```

### 05-heex-templates
**Status**: Production Ready  
**Purpose**: Template compilation system with Phoenix components

**Key Features Demonstrated**:
- HEEx template processing
- Phoenix component integration
- Template compilation
- Component generation

**How to Run**:
```bash
cd examples/05-heex-templates
npx haxe build.hxml
```

### 06-user-management
**Status**: Production Ready  
**Purpose**: Multi-annotation integration showcase

**Key Features Demonstrated**:
- Multiple annotation usage on single project
- @:schema + @:changeset integration
- @:liveview real-time components
- @:genserver background processes
- Cross-module communication

**Components**:
- `Users.hx` (@:schema + @:changeset) - Ecto schema and validation
- `UserGenServer.hx` (@:genserver) - OTP background processes
- `UserLive.hx` (@:liveview) - Phoenix real-time interface

**How to Run**:
```bash
cd examples/06-user-management
npx haxe build.hxml
```

### test-integration
**Status**: Production Ready  
**Purpose**: Package resolution and basic compilation verification

**Key Features Demonstrated**:
- Package structure alignment
- Import resolution
- Basic compilation testing

**How to Run**:
```bash
cd examples/test-integration
npx haxe build.hxml
```

## Common Patterns

### Annotation Usage
All examples demonstrate proper annotation usage:
```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
}
```

### Build Configuration
Standard build configuration pattern:
```hxml
-cp src_haxe
-cp ../../src
-cp ../../std
-lib reflaxe
-D reflaxe_runtime
--no-output

# List all modules to compile
ModuleName
AnotherModule
```

### Testing Integration
All examples include proper testing setup:
- Individual compilation testing
- Integration with comprehensive test suite
- Performance validation

## Development Workflow

1. **Create Haxe source files** in `src_haxe/` directory
2. **Add appropriate annotations** (@:schema, @:liveview, etc.)
3. **Configure build.hxml** with proper classpaths and modules
4. **Compile with** `npx haxe build.hxml`
5. **Test generated code** in Elixir/Phoenix environment

## Troubleshooting

### Common Issues
- **"Type not found"**: Check package structure matches directory structure
- **Function visibility**: Ensure utility functions are `public static`
- **Annotation conflicts**: Use annotation system to detect incompatible combinations
- **Build failures**: Check classpath configuration and dependencies

### Performance Tips
- Use unified compilation instead of `--next` approach
- All modules compile in <1ms typically
- Leverage caching for repeated builds

For more detailed technical information, see FEATURES.md and ANNOTATIONS.md.
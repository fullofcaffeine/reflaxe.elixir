# Example Details

## BasicModule.hx → BasicModule.ex

**Key Features Demonstrated:**
- `@:module` annotation eliminates `public static` boilerplate
- Simple function definitions with type signatures
- Pattern matching in switch statements
- Parameter handling and return values

**Before (Traditional Haxe):**
```haxe
class BasicModule {
    public static function hello(): String {
        return "world";
    }
    
    public static function greet(name: String): String {
        return "Hello, " + name + "!";
    }
}
```

**After (Reflaxe.Elixir with @:module):**
```haxe
@:module
class BasicModule {
    function hello(): String {
        return "world";
    }
    
    function greet(name: String): String {
        return "Hello, " + name + "!";
    }
}
```

**Compiled Elixir Output:**
```elixir
defmodule BasicModule do
  def hello, do: "world"
  def greet(name), do: "Hello, #{name}!"
end
```

## MathHelper.hx → MathHelper.ex

**Key Features Demonstrated:**
- Pipe operators (`|>`) for functional composition
- Data transformation pipelines
- Method chaining with clean syntax
- Multiple parameter functions in pipelines

**Pipeline Example:**
```haxe
function processNumber(x: Float): Float {
    return x
           |> multiplyByTwo()
           |> addTen()
           |> Math.round();
}
```

**Compiled to Elixir:**
```elixir
def process_number(x) do
  x
  |> multiply_by_two()
  |> add_ten()
  |> Float.round()
end
```

## UserUtil.hx → UserUtil.ex

**Key Features Demonstrated:**
- `@:private` annotation for private functions (`defp`)
- Public API with private implementation details
- Proper encapsulation patterns
- Validation and formatting helpers

**Public/Private Pattern:**
```haxe
private typedef User = {
    name: String,
    email: String,
    id: String,
    createdAt: String
}

@:module
class UserUtil {
    // Public function - accessible from outside
    function createUser(name: String, email: String): User {
        if (!isValidName(name)) {
            throw "Invalid name";
        }
        return formatUser(name, email);
    }
    
    // Private function - internal use only
    @:private
    function isValidName(name: String): Bool {
        return name != null && name.length > 0;
    }
}
```

**Compiled to Elixir:**
```elixir
defmodule UserUtil do
  def create_user(name, email) do
    unless is_valid_name(name) do
      raise "Invalid name"
    end
    format_user(name, email)
  end
  
  defp is_valid_name(name) do
    name != nil and String.length(name) > 0
  end
end
```

## Compilation Process

1. **Source**: Write Haxe code with `@:module` annotation
2. **Compilation**: Use `haxe CompileName.hxml` to compile
3. **Output**: Generated Elixir module in `output/` directory
4. **Comparison**: Compare with hand-written equivalent in `expected/`

## Best Practices Demonstrated

### Module Organization
- One module per file
- Clear public API with private helpers
- Proper function naming conventions

### Function Design
- Small, focused functions
- Clear parameter types
- Predictable return values

### Pipeline Usage
- Use pipes for data transformation
- Keep pipeline steps simple and testable
- Combine validation and processing logically

## Next Steps

After understanding these simple modules:
1. Learn Mix project integration in `../02-mix-project/`
2. Explore Phoenix controllers in `../03-phoenix-controllers/`
3. Build interactive features with `../04-phoenix-liveview/`

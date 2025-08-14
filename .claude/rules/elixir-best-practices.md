# Elixir Development Best Practices for CafeteraOS

## Code Quality Standards

### 🚨 CRITICAL: Warning Resolution Protocol

**MANDATORY REQUIREMENT**: All Elixir warnings MUST be resolved before task completion.

#### **Zero Tolerance for Warnings**
```bash
# All warnings must be resolved:
warning: unused alias Node
warning: variable "opts" is unused
warning: module attribute @cb_states was set but never used
warning: the following clause will never match (typing violations)
warning: the underscored variable "_working_context" is used after being set
```

#### **Warning Resolution Guidelines**

**1. Unused Aliases/Imports**
```elixir
# BAD: Unused alias
alias Cafetera.Core.Node  # Warning: unused alias Node

# GOOD: Remove unused aliases or use them
alias Cafetera.Core.Node
Node.changeset(%Node{}, attrs)

# ALTERNATIVE: Remove if truly unused
# alias Cafetera.Core.Node  # Commented out or removed
```

**2. Unused Variables**
```elixir
# BAD: Unused variable
defp some_function(query, opts) do  # Warning: variable "opts" is unused
  process_query(query)
end

# GOOD: Prefix with underscore or use pattern matching
defp some_function(query, _opts) do  # No warning
  process_query(query)
end

# BETTER: Use the variable if it has purpose
defp some_function(query, opts) do
  timeout = Keyword.get(opts, :timeout, 5000)
  process_query(query, timeout)
end
```

**3. Unused Module Attributes**
```elixir
# BAD: Defined but never used
@cb_states [:closed, :open, :half_open]  # Warning: never used

# GOOD: Use the attribute
@cb_states [:closed, :open, :half_open]
def valid_states, do: @cb_states

# ALTERNATIVE: Remove if not needed
# Remove the @cb_states line entirely
```

**4. Pattern Matching Issues**
```elixir
# BAD: Unreachable clauses
case result do
  {:ok, data} -> handle_success(data)
  {:error, reason} -> handle_error(reason)  # May warn if unreachable
end

# GOOD: Ensure all patterns are reachable
case result do
  {:ok, data} when is_map(data) -> handle_success(data)
  {:ok, data} -> handle_simple_success(data)
  {:error, reason} -> handle_error(reason)
end
```

**5. Variable Shadowing**
```elixir
# BAD: Variable shadowing in pattern matching
score = 0.5
case condition do
  true -> 
    score = score + 0.3  # Warning: score is unused (shadowed)
    score
end

# GOOD: Use proper variable naming or pin operator
base_score = 0.5
case condition do
  true -> 
    new_score = base_score + 0.3
    new_score
end

# ALTERNATIVE: Use pin operator when intentional
score = 0.5
case condition do
  true -> 
    updated_score = score + 0.3
    updated_score
end
```

### **Warning Resolution Process**

#### **Before Task Completion**
```bash
# 1. Compile with warnings visible
MIX_ENV=test mix compile --warnings-as-errors

# 2. Review all warnings systematically
# 3. Fix each warning using appropriate pattern
# 4. Re-compile to confirm resolution
# 5. Verify no new warnings introduced
```

#### **Common Warning Patterns and Solutions**

| Warning Type | Solution Pattern | Example |
|-------------|------------------|---------|
| `unused alias` | Remove or use the alias | `# alias Module` or use it |
| `unused variable` | Prefix with `_` or use it | `_opts` or `Keyword.get(opts, :key)` |
| `unused import` | Remove or use imported function | Remove unused import line |
| `module attribute unused` | Use attribute or remove | `def get_states, do: @states` |
| `clause never matches` | Fix pattern matching logic | Ensure all clauses are reachable |
| `variable shadowing` | Rename variables properly | Use unique variable names |
| `typing violations` | Fix type inconsistencies | Ensure return types match patterns |

## Development Workflow Standards

### **Pre-Commit Quality Gates**
```bash
# MANDATORY checks before any commit:
mix format              # Code formatting
mix credo              # Code quality analysis  
mix dialyzer           # Type checking
mix test               # Test suite
mix compile --warnings-as-errors  # Zero warnings policy
```

### **Code Organization Best Practices**

#### **Module Structure**
```elixir
defmodule Cafetera.ComponentName do
  @moduledoc """
  Clear, comprehensive module documentation.
  Explains purpose, usage, and key concepts.
  """
  
  # Module attributes (constants, configuration)
  @default_timeout 5000
  @valid_states [:pending, :active, :completed]
  
  # Type specifications
  @type t :: %__MODULE__{}
  
  # Public API functions (documented)
  def public_function(arg1, opts \\ []) do
    # Implementation
  end
  
  # Private helper functions
  defp private_helper(data) do
    # Implementation
  end
end
```

#### **Function Documentation**
```elixir
@doc """
Comprehensive function documentation with examples.

## Parameters
- `data`: Input data to process
- `opts`: Optional keyword list with configuration

## Returns
- `{:ok, result}`: Success with processed result
- `{:error, reason}`: Failure with error reason

## Examples
    iex> MyModule.process_data(%{key: "value"})
    {:ok, processed_result}
"""
def process_data(data, opts \\ [])
```

### **Error Handling Standards**

#### **Consistent Error Patterns**
```elixir
# GOOD: Consistent error handling
def process_data(data) when is_map(data) do
  with {:ok, validated} <- validate_data(data),
       {:ok, processed} <- transform_data(validated),
       {:ok, result} <- save_data(processed) do
    {:ok, result}
  else
    {:error, reason} -> {:error, reason}
    error -> {:error, {:unexpected_error, error}}
  end
end

def process_data(_invalid), do: {:error, :invalid_input}
```

#### **Proper Logging Integration**
```elixir
require Logger

def risky_operation(data) do
  Logger.debug("Starting risky operation with: #{inspect(data)}")
  
  case perform_operation(data) do
    {:ok, result} ->
      Logger.info("Operation completed successfully")
      {:ok, result}
      
    {:error, reason} ->
      Logger.warning("Operation failed: #{inspect(reason)}")
      {:error, reason}
  end
end
```

### **Testing Integration Standards**

#### **Test Organization**
```elixir
defmodule Cafetera.ComponentTest do
  use ExUnit.Case, async: true
  use Cafetera.DataCase  # When database needed
  
  alias Cafetera.Component
  
  describe "public_function/2" do
    test "should handle valid input successfully" do
      # Given: Valid input data
      input = %{key: "valid_value"}
      
      # When: Function is called
      {:ok, result} = Component.public_function(input)
      
      # Then: Should return expected result
      assert result.status == :processed
      assert result.data.key == "valid_value"
    end
    
    test "should return error for invalid input" do
      # Given: Invalid input
      invalid_input = "not_a_map"
      
      # When: Function is called
      result = Component.public_function(invalid_input)
      
      # Then: Should return error
      assert {:error, :invalid_input} = result
    end
  end
end
```

### **Performance Considerations**

#### **Efficient Data Processing**
```elixir
# GOOD: Efficient enumeration
def process_large_dataset(items) do
  items
  |> Stream.filter(&valid_item?/1)
  |> Stream.map(&transform_item/1)  
  |> Enum.into([])
end

# GOOD: Proper pattern matching
def handle_response({:ok, %{"data" => data, "status" => "success"}}) do
  process_success_data(data)
end

def handle_response({:error, reason}) do
  {:error, reason}
end
```

#### **Memory Management**
```elixir
# GOOD: Avoid accumulating large data in memory
def process_file_stream(file_path) do
  file_path
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.filter(&(&1 != ""))
  |> Enum.each(&process_line/1)
end
```

## Architecture Integration Standards

### **CafeteraOS-Specific Patterns**

#### **Memory-First Design**
```elixir
# GOOD: Always capture memory context
def create_node(attrs) do
  attrs
  |> Node.changeset(%Node{})
  |> capture_memory_context()  # Automatic memory integration
  |> Repo.insert()
end

defp capture_memory_context(changeset) do
  context = %{
    session_id: generate_session_id(),
    captured_at: DateTime.utc_now(),
    current_project: get_current_project()
  }
  put_change(changeset, :memory_context, context)
end
```

#### **Taskmaster Integration**
```elixir
# GOOD: Proper Taskmaster sync patterns
def sync_with_taskmaster(node) do
  with {:ok, task_data} <- extract_task_data(node),
       {:ok, synced} <- Taskmaster.sync_task(task_data),
       {:ok, updated_node} <- update_node_metadata(node, synced) do
    {:ok, updated_node}
  else
    {:error, reason} -> 
      Logger.warning("Taskmaster sync failed: #{inspect(reason)}")
      {:error, {:sync_failed, reason}}
  end
end
```

### **Integration Testing Patterns**

#### **Component Integration Testing**
```elixir
# GOOD: Testing component interactions
defmodule ComponentIntegrationTest do
  test "modules work together correctly" do
    # Test real integration between modules
    {:ok, result} = ModuleA.process(ModuleB.prepare(data))
    assert result.status == :success
  end
end
```

## Quality Gates and Enforcement

### **Pre-Task Completion Checklist**
- [ ] **🚨 ZERO WARNINGS**: All Elixir warnings resolved
- [ ] **🧪 TESTS PASS**: Full test suite passes
- [ ] **🔍 STATIC ANALYSIS**: Credo, Dialyzer clean
- [ ] **📝 DOCUMENTATION**: Public functions documented
- [ ] **🏗️ PATTERNS**: Follows CafeteraOS architecture patterns
- [ ] **⚡ PERFORMANCE**: No obvious performance issues
- [ ] **🧠 MEMORY**: Proper memory context integration

### **Automated Enforcement**
```bash
# These should be integrated into CI/CD pipeline:
mix format --check-formatted
mix credo --strict
mix dialyzer  
mix test --warnings-as-errors
mix compile --warnings-as-errors
```

## Success Metrics

✅ **ZERO COMPILATION WARNINGS**: Clean compilation output
✅ **CONSISTENT CODE STYLE**: Follows established patterns  
✅ **PROPER ERROR HANDLING**: Robust error management
✅ **COMPREHENSIVE TESTING**: Integration-focused test coverage
✅ **CLEAR DOCUMENTATION**: Well-documented public APIs
✅ **PERFORMANCE AWARENESS**: Efficient resource usage
✅ **ARCHITECTURE ALIGNMENT**: Follows CafeteraOS design principles

**🚨 KEY PRINCIPLE: Code quality is not negotiable - warnings and issues must be resolved before task completion.**

This ensures that CafeteraOS maintains high code quality standards while following Elixir best practices and the memory-first architecture design principles.
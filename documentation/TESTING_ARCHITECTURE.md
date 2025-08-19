# Reflaxe.Elixir Testing Architecture

This document explains the comprehensive testing strategy for Reflaxe.Elixir, covering both **compiler testing** and **application testing** patterns.

## 🎯 Core Architectural Insight

**Examples are E2E tests for the compiler.** This elegant pattern means real applications like `todo-app` serve as comprehensive integration tests for the entire Haxe→Elixir→BEAM compilation pipeline.

## 🏗️ Two-Layer Architecture

### **Layer 1: The Compiler** (`/src/reflaxe/elixir/`)
- **What**: Haxe macro-based transpiler (TypedExpr → Elixir code)
- **Runs**: Only during Haxe compilation (macro-time)
- **Language**: Written in Haxe
- **Output**: Generates `.ex` files, then disappears

### **Layer 2: Applications** (`/examples/`)
- **What**: Phoenix/Elixir applications written in Haxe
- **Runs**: On BEAM VM in production
- **Language**: Haxe source → compiled Elixir
- **Purpose**: Real apps + compiler E2E validation

## 🧪 Complete Testing Matrix

### Compiler Testing Strategy

| Test Type | Location | Tools | Purpose | What's Tested |
|-----------|----------|-------|---------|---------------|
| **Snapshot Tests** | `/test/tests/` | Haxe test framework | AST → Elixir validation | Code generation correctness |
| **Compile-time Tests** | `/test/` | Haxe macros | Macro validation | Error messages, warnings |
| **Mix Integration** | `/test/*.exs` | ExUnit | Basic Elixir compilation | Generated code compiles |
| **Examples (E2E)** | `/examples/` | Phoenix projects | **Full pipeline testing** | Haxe → Elixir → BEAM → Runtime |

### Application Testing Strategy

| Test Type | Location | Tools | Purpose | What's Tested |
|-----------|----------|-------|---------|---------------|
| **Unit Tests** | `examples/*/test/unit/` | Haxe test framework | Business logic | Pure Haxe functions |
| **Integration Tests** | `examples/*/test/live/` | ExUnit (via Haxe) | Phoenix features | LiveView, Channels, Contexts |
| **Browser Tests** | `examples/*/test/e2e/` | Wallaby | User workflows | Real browser interactions |
| **Real-time Tests** | `examples/*/test/channels/` | Phoenix Channel tests | WebSocket features | PubSub, presence |

## 🎭 Examples as E2E Tests: Deep Dive

### Why This Pattern Works

**Traditional E2E testing problems:**
- Artificial test scenarios don't match real usage
- Complex setup for realistic test data
- Maintenance overhead for test-specific code
- Gap between "toy examples" and production code

**Examples-as-E2E-tests solution:**
- ✅ **Real applications** with genuine complexity
- ✅ **Authentic use cases** that users actually need
- ✅ **Self-maintaining** - they must work for users
- ✅ **Living documentation** - show best practices
- ✅ **Continuous validation** - every `mix compile` is a test

### What Examples Test

**Complete Compilation Pipeline:**
```
Haxe Source (.hx files)
    ↓ [Reflaxe.Elixir compiler]
Generated Elixir (.ex files)  
    ↓ [Elixir compiler]
BEAM Bytecode (.beam files)
    ↓ [BEAM VM]
Running Phoenix Application
    ↓ [Browser/Client]
Real User Interactions
```

**Real-World Integration Points:**
- **Framework integration**: Phoenix, Ecto, OTP patterns work correctly
- **Language interop**: Generated Elixir integrates with existing Elixir ecosystem
- **Performance characteristics**: Compilation speed, runtime performance
- **Error propagation**: Haxe errors map to correct source locations
- **Build system integration**: Mix tasks, hot reloading, asset pipeline
- **Deployment readiness**: Applications can be packaged and deployed

### Current Examples

#### `todo-app` - Primary E2E Test
**Validates:**
- ✅ Phoenix LiveView integration
- ✅ HXX template compilation
- ✅ Router DSL functionality  
- ✅ Ecto schema generation
- ✅ Real-time PubSub features
- ✅ Asset pipeline (JavaScript compilation)
- ✅ Type-safe error handling
- ✅ Database migrations

**Complexity Level:** Production-ready application with:
- ~15 Haxe source files
- Multiple LiveView components
- Database integration
- Real-time features
- Client-side JavaScript
- Asset compilation pipeline

**E2E Test Commands:**
```bash
# Full E2E validation
cd examples/todo-app
rm -rf lib/*.ex lib/**/*.ex    # Clean slate
npx haxe build-server.hxml     # Compiler test
mix compile --force            # Elixir compilation test  
mix phx.server                 # Runtime test
curl http://localhost:4000     # HTTP test
```

## 🚀 Development Feedback Loop

### Compiler Development Cycle
1. **Change compiler** (`/src/reflaxe/elixir/`)
2. **Run snapshot tests** (`npm test`) 
3. **Test with examples** (`cd examples/todo-app && mix compile`)
4. **Fix compiler issues** if examples fail
5. **Update snapshots** if output improved
6. **Examples validate** new compiler features

### Application Development Cycle  
1. **Add feature to example** (`examples/todo-app/src_haxe/`)
2. **Discover compiler limitations**
3. **Enhance compiler** to support new patterns
4. **Extract patterns to framework** (`/std/phoenix/`)
5. **Other applications benefit** from improvements

## 🎯 Testing Principles

### For Compiler Testing

**✅ DO:**
- Write snapshot tests for new AST transformations
- Use examples to validate real-world usage
- Test error message quality and source mapping
- Benchmark compilation performance
- Validate output against Phoenix conventions

**❌ DON'T:**
- Try to unit test the compiler directly (macro-time vs runtime)
- Create artificial test scenarios that don't match real usage
- Skip testing examples after compiler changes
- Accept poor error messages or confusing diagnostics

### For Application Testing

**✅ DO:**
- Write tests in Haxe using ExUnit externs
- Test business logic with unit tests
- Use integration tests for Phoenix features
- Add browser tests for user workflows
- Test real-time features with multiple sessions

**❌ DON'T:**
- Write Elixir test files directly (breaks Haxe-first philosophy)
- Skip testing real-time/concurrent features
- Test only happy paths (validate error handling)
- Ignore performance and load testing

## 🔄 Continuous Integration Strategy

### Compiler CI Pipeline
```yaml
1. Run Haxe unit tests
2. Run snapshot tests (validate code generation)
3. Compile all examples (E2E validation)
4. Run example test suites
5. Performance benchmarks
6. Documentation builds
```

### Example Application CI
```yaml
1. Compile Haxe to Elixir
2. Run ExUnit test suite  
3. Run browser/E2E tests
4. Load testing (if applicable)
5. Security scanning
6. Deployment testing
```

## 📊 Quality Metrics

### Compiler Quality Indicators
- **Snapshot test coverage**: >95% of AST transformations tested
- **Example compilation success**: 100% - all examples must compile
- **Compilation speed**: <2s for full todo-app rebuild
- **Error quality**: All compiler errors include source positions
- **Framework compliance**: Generated code follows Phoenix conventions

### Application Quality Indicators  
- **Test coverage**: >90% of business logic
- **Real-time feature coverage**: All PubSub/Channel features tested
- **Browser compatibility**: Modern browsers (last 2 versions)
- **Performance**: <100ms average response time
- **Type safety**: Zero `Dynamic` usage in application code

## 🛠️ Testing Tools Reference

### Compiler Testing Tools
- **Haxe Test Framework**: Unit tests for macro logic
- **Snapshot Testing**: Compare AST output against golden files
- **Mix Tasks**: Integration with Elixir build system
- **Source Maps**: Error location validation

### Application Testing Tools
- **ExUnit (via Haxe)**: Phoenix integration testing
- **Wallaby**: Browser automation for E2E tests
- **Phoenix ChannelTest**: Real-time feature testing
- **Performance Testing**: Load testing tools

## 🎯 Best Practices

### Writing Effective Snapshot Tests
```haxe
// Test specific compiler features with minimal examples
@:test
class RouterCompilerTest {
    @:test
    function testBasicRoute() {
        var source = '@:route("GET", "/users", UserController, index)';
        var expected = 'get "/users", UserController, :index';
        assertSnapshot(source, expected);
    }
}
```

### Writing Effective Integration Tests
```haxe
// Test Phoenix features through type-safe Haxe interfaces
@:exunit
class TodoLiveTest extends TestCase {
    @:test  
    function testCreateTodo() {
        var {view, html} = LiveViewTest.render(TodoLive);
        var form = LiveViewTest.form(view, "#todo-form", {title: "New todo"});
        LiveViewTest.submitForm(form);
        Assert.hasElement(view, "[data-testid='todo-item']", "New todo");
    }
}
```

### Maintaining Examples as E2E Tests
1. **Keep examples realistic** - Use patterns that real applications need
2. **Add complexity gradually** - Start simple, add features over time
3. **Document patterns** - Extract reusable patterns to framework
4. **Validate continuously** - Every compiler change must pass example compilation
5. **Performance awareness** - Examples should compile quickly

---

**Key Insight**: The examples-as-E2E-tests pattern creates a powerful feedback loop where real applications drive compiler improvements, ensuring the compiler serves practical needs rather than theoretical requirements.
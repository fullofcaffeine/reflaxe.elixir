# Phoenix Test Suite Context for AI Assistants

> **Parent Context**: See [/test/AGENTS.md](/test/AGENTS.md) for overall testing infrastructure

## 🎯 Purpose of Phoenix Tests

This directory contains tests for Phoenix framework integration features, including both backend (Elixir) and frontend (JavaScript) capabilities that enable full-stack Phoenix development in Haxe.

## 🌐 Full-Stack Phoenix Framework Support

**CRITICAL UNDERSTANDING**: Reflaxe.Elixir is not just an Elixir compiler - it's a **full-stack Phoenix development framework** that enables writing entire Phoenix applications (including client-side JavaScript) in pure Haxe.

### Why JavaScript Tests Exist Here

The compiler includes **genes** (JavaScript generator) integration to support:
- **Phoenix LiveView JavaScript hooks** - Type-safe client-side interactivity
- **Phoenix Channel JavaScript clients** - Real-time WebSocket communication
- **Asset pipeline integration** - JavaScript that works with Phoenix's esbuild
- **Shared types between frontend/backend** - Single source of truth for data structures
- **Modern ES6 with async/await** - Clean JavaScript output for Phoenix apps

### The Async/Await Extension

Since Haxe doesn't have native async/await syntax (like TypeScript), we provide:
- **`@:async` and `@:await` metadata** - Clean syntax similar to TypeScript
- **`genes.AsyncMacro`** - Transforms metadata into proper ES6 async/await
- **Full Promise<T> type safety** - Compile-time checking of async operations
- **1:1 JavaScript parity** - Generated code looks hand-written

**Example Usage:**
```haxe
@:build(genes.AsyncMacro.build())
class LiveViewHooks {
    @:async
    public static function loadMoreData(pushEvent: Dynamic): Promise<Array<Todo>> {
        var response = @:await pushEvent("load-more", {page: 2});
        var todos = @:await response.json();
        return todos;
    }
}
```

## 📁 Test Categories in Phoenix Directory

### Backend Tests (Elixir Generation)
- **LiveView components** - Server-rendered interactive UIs
- **Router DSL** - Phoenix routing with compile-time validation
- **Presence** - Real-time user tracking
- **Channels** - WebSocket communication
- **Controllers** - HTTP request handling
- **Plugs** - Middleware pipeline
- **HXX templates** - Type-safe HEEx template generation

### Frontend Tests (JavaScript Generation)
- **`js_async_await`** - Tests async/await transformation for Phoenix hooks
- **JavaScript interop** - Phoenix.Socket, Phoenix.LiveSocket JavaScript APIs
- **Shared types** - Types used on both client and server

### Negative Tests (Expected to Fail)
- **`HXXTypeSafetyErrors`** - Verifies type safety by expecting compilation failures
- These tests ensure the type system properly rejects invalid code

## ⚠️ IMPORTANT: Understanding Test Types

### Standard Positive Tests
Most tests should compile successfully and generate correct output:
```bash
# These should pass compilation and generate correct Elixir
test/snapshot/phoenix/liveview/
test/snapshot/phoenix/router/
test/snapshot/phoenix/presence/
```

### JavaScript Generation Tests
Some tests generate JavaScript instead of Elixir:
```bash
# The js_async_await test generates JavaScript, not Elixir
test/snapshot/core/js_async_await/  # Generates out/main.js
```

**Note**: These are still valid tests! They test the full-stack framework capabilities.

### Negative Tests (Expected Failures)
Some tests INTENTIONALLY contain type errors to verify compile-time safety:
```bash
# HXXTypeSafetyErrors should FAIL compilation with specific error messages
test/snapshot/phoenix/HXXTypeSafetyErrors/  # No output expected - should fail
```

**Success Criteria for Negative Tests**:
- Compilation fails with clear, helpful error messages
- Each type error is properly identified
- Suggestions are provided where possible

## 🔧 Testing Phoenix Features

### LiveView Tests
```bash
# Test LiveView component compilation
./scripts/test-runner.sh --pattern "liveview"
```

### Router Tests
```bash
# Test Phoenix router DSL
./scripts/test-runner.sh --pattern "router"
```

### JavaScript Tests
```bash
# Test async/await and JavaScript generation
./scripts/test-runner.sh --pattern "js_async_await"
# Note: Output will be in out/main.js, not out/Main.ex
```

### Negative Tests
```bash
# These should FAIL compilation - that's success!
npx haxe test/snapshot/phoenix/HXXTypeSafetyErrors/compile.hxml
# Expected: Compilation errors about invalid attributes and type mismatches
```

## 📚 Full-Stack Development Flow

The complete Phoenix development experience in Haxe:

1. **Backend (Elixir)**:
   - Write LiveView components, schemas, contexts in Haxe
   - Compile to idiomatic Elixir with `npx haxe build-server.hxml`
   - Full Phoenix framework support

2. **Frontend (JavaScript)**:
   - Write LiveView hooks, channel clients in Haxe
   - Use `@:async`/`@:await` for clean async code
   - Compile to ES6 with `npx haxe build-client.hxml`
   - Integrates with Phoenix's asset pipeline

3. **Shared Types**:
   - Define types once in Haxe
   - Use on both backend and frontend
   - Compile-time type safety across the stack

## 🎯 Why This Matters

**The Vision**: Write entire Phoenix applications in pure Haxe with:
- **100% type safety** - Frontend and backend
- **Modern JavaScript** - Clean ES6 with async/await
- **Phoenix idioms** - Generated code follows Phoenix patterns
- **Single language** - No context switching between Elixir and JavaScript
- **Shared business logic** - Validation, calculations work on both sides

## 📖 Documentation References

- **Async/Await Specification**: See `docs/04-api-reference/async-await-specification.md`
- **genes Integration**: See `vendor/genes/README.md`
- **Full-Stack Guide**: See `docs/02-user-guide/full-stack-phoenix.md`
- **HXX Template Guide**: See `docs/02-user-guide/hxx-templates.md`

## ⚠️ Common Misconceptions to Avoid

1. **"js_async_await test is broken"** - No, it generates JavaScript, not Elixir
2. **"HXXTypeSafetyErrors test fails"** - Yes, that's the point! It tests type safety
3. **"Why JavaScript in Elixir tests?"** - We're testing full-stack Phoenix capabilities
4. **"These tests have wrong paths"** - JavaScript tests may use different configurations

---

**Remember**: Reflaxe.Elixir is a complete Phoenix development platform, not just an Elixir compiler. Tests reflect this full-stack capability.
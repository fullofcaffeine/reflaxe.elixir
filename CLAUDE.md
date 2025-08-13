# AI/Agent Development Context for Haxe→Elixir Compiler

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions
- Move historical completions to [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)
- Reference other docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`
- See [`documentation/DOCUMENTATION_PHILOSOPHY.md`](documentation/DOCUMENTATION_PHILOSOPHY.md) for documentation structure

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify CLAUDE.md first** - This file contains the project truth
2. **FOLLOW DOCUMENTATION GUIDE** - See [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) for how to document
3. **UNDERSTAND THE ARCHITECTURE** - See [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) section below
4. **Check referenced documentation** - See documentation/*.md files for feature details
5. **Consult Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/documentation/introduction/ - Language documentation
6. **Use modern Haxe 4.3+ patterns** - No legacy idioms
7. **KEEP DOCS UPDATED** - Documentation is part of implementation, not separate

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) - How the transpiler actually works
- [Critical: Macro-Time vs Runtime](#critical-macro-time-vs-runtime-) - THE MOST IMPORTANT CONCEPT TO UNDERSTAND
- [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md) - Complete architectural details
- [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Testing philosophy and infrastructure

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime. This affects how you write and test compiler features.

**Key Point**: The function body compilation fix was a legitimate use case - we went from empty function bodies (`# TODO: Implement function body`) to real compiled Elixir code. This required updating all intended outputs to reflect the improved compiler behavior.

## 📍 Agent Navigation Guide

### When Writing or Fixing Tests
→ **MUST READ**: [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md) - Critical testing rules, snapshot testing, simplification principles
→ **Architecture**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Technical testing infrastructure
→ **Deep Dive**: [`documentation/TEST_SUITE_DEEP_DIVE.md`](documentation/TEST_SUITE_DEEP_DIVE.md) - What each test validates

### When Implementing New Features  
→ **Process**: Follow TDD methodology (RED-GREEN-REFACTOR)
→ **Testing**: Create snapshot tests following patterns in TESTING_PRINCIPLES.md
→ **Documentation**: Update relevant guides in `documentation/`

### When Refactoring Code
→ **Safety**: Ensure all tests pass before and after changes
→ **Simplification**: Apply "as simple as needed" principle (see TESTING_PRINCIPLES.md)
→ **Documentation**: Update if behavior or API changes

### When Debugging Compilation Issues
→ **Source Maps**: See [`documentation/SOURCE_MAPPING.md`](documentation/SOURCE_MAPPING.md)
→ **Architecture**: Understand macro-time vs runtime (see sections below)
→ **Examples**: Check `test/tests/` for similar patterns

## User Documentation References

### Core Documentation
- **Project Overview**: See [README.md](README.md) for project introduction and public interface
- **LLM Documentation Guide**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) 📚
- **Setup & Installation**: [`documentation/GETTING_STARTED.md`](documentation/GETTING_STARTED.md)
- **Mix Integration**: [`documentation/MIX_INTEGRATION.md`](documentation/MIX_INTEGRATION.md) ⚡ **NEW**
- **Feature Status**: [`documentation/FEATURES.md`](documentation/FEATURES.md)
- **Annotations**: [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md)
- **Examples**: [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md)
- **Architecture**: [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)
- **Testing**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md)
- **Development Tools**: [`documentation/DEVELOPMENT_TOOLS.md`](documentation/DEVELOPMENT_TOOLS.md)
- **Task History**: [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)

## Reference Code Location
Reference examples for architectural patterns are located at:
`/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`

This directory contains:
- **Reflaxe projects** - Examples of DirectToStringCompiler implementations and Reflaxe target patterns
- **Phoenix projects** - Phoenix/LiveView architectural patterns and Mix task organization
- **Haxe macro projects** - Compile-time transformation macro examples for HXX processing reference
- **Haxe source code** - The Haxe compiler source at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe` for API reference
- **Reflaxe source** - The Reflaxe framework source for understanding compiler patterns
- **Reference implementations** - Working Reflaxe targets for comparison and pattern reference
- **Haxe API documentation** - Can check API at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe/std/` for standard library

## Project Context
Implementing Reflaxe.Elixir - a Haxe compilation target for Elixir/BEAM with gradual typing support for Phoenix applications.

## Reflaxe.CPP Architecture Pattern (Reference)
Based on analysis of `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe.CPP/`:

### Sub-compiler Pattern
- Main `Compiler` delegates to specialized sub-compilers in `subcompilers/` package
- Each sub-compiler handles specific compilation aspects:
  - `Classes.hx` - Class declarations and struct compilation
  - `Enums.hx` - Enum compilation
  - `Expressions.hx` - Expression compilation
  - `Types.hx` - Type resolution and mapping
  - `Includes.hx` - Include management
  - `Dynamic.hx` - Dynamic type handling

### Our Implementation Alignment
Currently using helper pattern instead of sub-compiler pattern:
- `helpers/EnumCompiler.hx` - Enum compilation (similar to Enums sub-compiler)
- `helpers/ClassCompiler.hx` - Class/struct compilation (similar to Classes sub-compiler)
- `helpers/ChangesetCompiler.hx` - Ecto changeset compilation with @:changeset annotation support
- `ElixirTyper.hx` - Type mapping (similar to Types sub-compiler)
- `ElixirPrinter.hx` - AST printing (similar role to expression compilation)

This is acceptable - helpers are simpler for our needs while following similar separation of concerns.

## Quality Standards
- Zero compilation warnings policy (from .claude/rules/elixir-best-practices.md)
- Testing Trophy approach with integration test focus
- Performance targets: <15ms compilation steps, <100ms HXX template processing

## Date and Timestamp Rule 📅
**ALWAYS check current date before writing timestamps**:
```bash
date  # Get current date/time before writing any timestamps
```
- Never assume dates - always verify with `date` command
- Use consistent format: "August 2025" or "2025-08-11"
- Update "Last Updated" timestamps when modifying documentation

## Commit Message Standards (Conventional Commits)
All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Important: No AI Attribution in Commits
**NEVER add AI attribution lines to commit messages**:
- ❌ Don't add "Generated with Claude Code"
- ❌ Don't add "Co-Authored-By: Claude"
- ✅ Write clean, professional commit messages without AI references

### Types
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or fixing tests
- `chore`: Maintenance tasks, dependency updates
- `ci`: CI/CD configuration changes

### Examples
```bash
fix(watcher): resolve directory context issue for relative paths

fix(tests): update error message expectations for Haxe compiler output

feat(compiler): add comprehensive Ecto query compilation support

docs(testing): add Process.send_after timing notes
```

### Breaking Changes
Mark breaking changes with `BREAKING CHANGE:` in the footer or `!` after the type:
```bash
feat!: change default compilation directory structure
```

### No Co-authorship or Generation Attribution
Do NOT add co-authorship lines or generation notes in commit messages. This includes:
- No `Co-Authored-By: Claude` lines
- No `🤖 Generated with Claude Code` or similar attribution
- No references to AI/agent assistance in commit messages
Commits should appear as direct contributions without attribution notes.

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Contains Reflaxe patterns, Phoenix examples, Haxe source
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
- **Web Resources**: Use WebSearch and WebFetch for current documentation, API references, and best practices
- **Principle**: Always reference existing working code and official documentation rather than guessing or assuming implementation details

## Implementation Status
For comprehensive feature status and production readiness, see [`documentation/reference/FEATURES.md`](documentation/reference/FEATURES.md)

### v1.0 Status ✅
- **Core Features**: ALL COMPLETE (11/11 production-ready)
- **Phoenix/LiveView**: Full support with HXX templates
- **Ecto Integration**: Complete with migrations and changesets
- **OTP Patterns**: GenServer, Supervisor, Application behaviors
- **Mix Integration**: File watcher, compilation, source mapping
- **LLM Documentation**: Auto-generated, template-based system
- **Project Generator**: Template-driven with AI-optimized docs
- **Testing**: 28 snapshot tests + 130 Mix tests ALL PASSING

## Development Environment Setup
- **Haxe Version**: 4.3.6+ (available at `/opt/homebrew/bin/haxe`)
- **Haxe API Reference**: https://api.haxe.org/ (latest version docs)
- **Haxe Documentation**: https://haxe.org/documentation/introduction/
- **Test Execution**: Use `haxe TestName.hxml` or `npm test` for full suite
- **Compilation Flags**: Always use `-D reflaxe_runtime` for test compilation
- **Test Structure**: All tests in `test/` directory with matching .hxml files
- **Reflaxe Base Classes**: Located at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe/src`

## Compiler Architecture & Modern Haxe Features
- **Output Model**: One `.ex` file per `.hx` file (1:1 mapping maintained)
- **Modern Haxe 4.3+ Features Used**:
  - Pattern matching with exhaustive checks
  - Null safety with `Null<T>` types
  - Abstract types for type-safe wrappers
  - Inline metadata for optimization
  - Expression macros for compile-time code generation
  - `using` for static extensions
  - Arrow functions in expressions
- **Avoided Legacy Patterns**:
  - No `Std.is()` (use `Std.isOfType()`)
  - No untyped code blocks
  - No Dynamic where generics suffice
  - Proper null handling instead of implicit nulls

## Dynamic Type Usage Guidelines ⚠️
**Dynamic should be used with caution** and only when necessary:
- ✅ **When to use Dynamic**: Catch blocks (error types vary), reflection operations, external API integration
- ✅ **Always add justification comment** when using Dynamic to explain why it's necessary
- ❌ **Avoid Dynamic when generics or specific types work** - prefer type safety
- 📝 **Example of proper Dynamic usage**:
  ```haxe
  } catch (e: Dynamic) {
      // Dynamic used here because Haxe's catch can throw various error types
      // Converting to String for error reporting
      EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
  }
  ```

## Test Status Summary
- **Full Test Suite**: ✅ ALL PASSING (snapshot tests + Mix tests)
- **Elixir Tests**: ✅ ALL PASSING (13 tests in Mix/ExUnit)
- **Haxe Tests**: ✅ ALL PASSING (snapshot tests via TestRunner.hx)
- **CI Status**: ✅ All GitHub Actions checks passing

## Reflaxe Snapshot Testing Architecture ✅

### Testing Approach
Reflaxe.Elixir uses **snapshot testing** following Reflaxe.CPP patterns:

- **TestRunner.hx**: Main test orchestrator that compiles Haxe files and compares output
- **test/tests/** directory structure with `compile.hxml` and `intended/` folders per test
- **Snapshot comparison**: Generated Elixir code compared against expected output files
- **Dual ecosystem**: Haxe compiler tests + separate Mix tests for runtime validation

### Test Structure
```
test/
├── TestRunner.hx          # Main test runner (Reflaxe snapshot pattern)
├── Test.hxml             # Entry point configuration
└── tests/
    ├── test_name/
    │   ├── compile.hxml  # Test compilation config
    │   ├── Main.hx       # Test source
    │   ├── intended/     # Expected Elixir output
    │   └── out/          # Generated output (for comparison)
```

### Key Commands
- `npm test` - Run all tests via TestRunner.hx
- `haxe test/Test.hxml test=name` - Run specific test
- `haxe test/Test.hxml update-intended` - Update expected output files
- `haxe test/Test.hxml show-output` - Show compilation details

## Understanding Reflaxe.Elixir's Compilation Architecture ✅

**For complete architectural details, see [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)**  

### How Reflaxe.Elixir Actually Works

Reflaxe.Elixir is a **Haxe macro-based transpiler** that transforms typed Haxe AST into Elixir code during compilation. 

#### Correct Compilation Flow

```
Haxe Source (.hx)
       ↓
   Haxe Parser → Untyped AST
       ↓
   Typing Phase → TypedExpr (ModuleType)
       ↓
   onAfterTyping callback (Reflaxe hooks here)
       ↓
   ElixirCompiler (macro-time transpilation)
       ↓
   Elixir Code (.ex files)
```

**Key Points**:
- **TypedExpr is created by Haxe**, not by our compiler
- **ElixirCompiler receives TypedExpr** as input (fully typed AST)
- **Transpilation happens at macro-time** via Context.onAfterTyping
- **No runtime component exists** - the transpiler disappears after compilation

## Critical: Macro-Time vs Runtime ⚠️

### THE FUNDAMENTAL DISTINCTION

**This is the #1 cause of confusion when working with Reflaxe compilers:**

```haxe
// MACRO-TIME: During Haxe compilation
#if macro
class ElixirCompiler extends BaseCompiler {
    // This class ONLY exists while Haxe is compiling
    // It transforms AST → Elixir code
    // Then it DISAPPEARS
}
#end

// RUNTIME: After compilation, when tests/code runs
class MyTest {
    function test() {
        // ElixirCompiler DOES NOT EXIST HERE
        // It already did its job and vanished
        var compiler = new ElixirCompiler(); // ❌ ERROR: Type not found
    }
}
```

### The Two Phases Explained

#### Phase 1: MACRO-TIME (Compilation)
```
When: While running `haxe build.hxml`
What exists: ElixirCompiler, all macro classes
What happens: 
  1. Haxe parses your .hx files
  2. Haxe creates TypedExpr AST
  3. ElixirCompiler receives AST
  4. ElixirCompiler generates .ex files
  5. Compilation ends, ElixirCompiler disappears
```

#### Phase 2: RUNTIME (Execution)
```
When: While running tests or compiled code
What exists: Your regular classes, NOT compiler classes
What happens:
  1. Test framework starts
  2. Tests execute
  3. ElixirCompiler is GONE - it doesn't exist
  4. Any attempt to use it fails
```

### Key Takeaways for Development

1. **Never try to instantiate ElixirCompiler in tests** - it doesn't exist at runtime
2. **Test the OUTPUT** - compile Haxe to Elixir, then validate the .ex files
3. **Use Mix tests** - they test that generated Elixir actually works
4. **The TypeTools.iter error** = wrong test configuration, not API incompatibility

## Known Issues (Updated)
- **Test Environment**: While Haxe 4.3.6 is available and basic compilation works, there are compatibility issues with our current implementation:
  - Missing `using StringTools` declarations causing trim/match method errors
  - Type system mismatches between macro types and expected Reflaxe types
  - Some Dynamic iteration issues that need proper typing
  - Keyword conflicts with parameter names (`interface`, `operator`, `overload`)
- **Pattern Matching Implementation**: Core logic completed but needs type system integration
- **Integration Tests**: Require mock/stub system for TypedExpr structures

## Testing Quick Reference

→ **CRITICAL: Test code modification rules**: See [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md#never-remove-test-code-to-fix-failures)
→ **All testing rules and patterns**: See [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md)
→ **Primary command**: `npm test` - runs all validation
→ **Architecture details**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md)

## Current Implementation Status Summary

### v1.0 ESSENTIAL Tasks Status (3/4 Complete - 75%)

✅ **1. Essential Elixir Protocol Support** - COMPLETE
   - ProtocolCompiler.hx fully implemented
   - @:protocol and @:impl annotations working
   - Examples in 07-protocols demonstrate functionality

✅ **2. Create Essential Standard Library Extern Definitions** - COMPLETE
   - All 9 essential modules implemented (Process, Registry, Agent, IO, File, Path, Enum, String, GenServer)
   - Full type-safe extern definitions with helper functions
   - Comprehensive test coverage

✅ **3. Implement Haxe Typedef Compilation Support** - COMPLETE ✨ NEW
   - TypedefCompiler.hx helper class fully implemented
   - Complete type mapping for aliases, structures, functions, generics
   - Snake_case field conversion and optional field handling
   - Comprehensive snapshot test coverage

❌ **4. Add Essential OTP Supervision Patterns** - PARTIALLY COMPLETE
   - Registry ✅ (completed as part of stdlib externs)
   - Supervisor ❌ (needs extern implementation)
   - Task/Task.Supervisor ❌ (needs extern implementation)

**For complete feature status, example guides, and usage instructions, see:**
- [`documentation/FEATURES.md`](documentation/FEATURES.md) - Production readiness status
- [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md) - Working example walkthroughs  
- [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md) - Annotation usage guide

**Quick Status**: 15 production-ready features, 9 working examples, 38/38 tests passing.

## Task Completion and Documentation Protocol

### CRITICAL AGENT INSTRUCTION ⚠️
After completing and verifying any task, you MUST:

1. **Update TASK_HISTORY.md** with comprehensive session documentation including:
   - Context and problem identification
   - Detailed implementation steps
   - Technical insights gained
   - Files modified
   - Key achievements
   - Development insights
   - Session summary with status

2. **Document task completion** before finalizing the session

This ensures:
- ✅ **Knowledge preservation** across development sessions
- ✅ **Context continuity** for future development
- ✅ **Quality tracking** and process improvement
- ✅ **Comprehensive project history** for team collaboration

**Example Pattern**:
```
## Session: [Date] - [Task Description]
### Context: [Problem/Request background]
### Tasks Completed ✅: [Detailed implementation list]
### Technical Insights Gained: [Architecture/pattern learnings]
### Files Modified: [Complete file change list]
### Key Achievements ✨: [Impact and value delivered]
### Session Summary: [Status and completion confirmation]
```

**NEVER skip task history documentation** - it's as important as the implementation itself.

## API Quick Reference (Auto-Generated)

### Module: haxe.io.Error

#### Error (enum)

	The possible IO errors that can occur


### Module: haxe.io.Encoding

#### Encoding (enum)

	String binary encoding supported by Haxe I/O


### Module: haxe.io.BytesData

#### BytesData (typedef)

### Module: haxe.ds.StringMap

#### StringMap (class)

	StringMap allows mapping of String keys to arbitrary values.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:String, value:T):Void`
- `get(key:String):Null`
- `exists(key:String):Bool`
- `remove(key:String):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():StringMap`
- `toString():String`
- `clear():Void`

### Module: haxe.ds.ReadOnlyArray

#### ReadOnlyArray (abstract)

	`ReadOnlyArray` is an abstract over an ordinary `Array` which only exposes
	APIs that don't modify the instance, hence "read-only".

	Note that this doesn't necessarily mean that the instance is *immutable*.
	Other code holding a reference to the underlying `Array` can still modify it,
	and the reference can be obtained with a `cast`.


### Module: haxe.ds.ObjectMap

#### ObjectMap (class)

	ObjectMap allows mapping of object keys to arbitrary values.

	On static targets, the keys are considered to be strong references. Refer
	to `haxe.ds.WeakMap` for a weak reference version.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:K, value:V):Void`
- `get(key:K):Null`
- `exists(key:K):Bool`
- `remove(key:K):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():ObjectMap`
- `toString():String`
- `clear():Void`

### Module: haxe.ds.Map

#### Map (abstract)

	Map allows key to value mapping for arbitrary value types, and many key
	types.

	This is a multi-type abstract, it is instantiated as one of its
	specialization types depending on its type parameters.

	A Map can be instantiated without explicit type parameters. Type inference
	will then determine the type parameters from the usage.

	Maps can also be created with `[key1 => value1, key2 => value2]` syntax.

	Map is an abstract type, it is not available at runtime.

	@see https://haxe.org/manual/std-Map.html


### Module: haxe.ds.IntMap

#### IntMap (class)

	IntMap allows mapping of Int keys to arbitrary values.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:Int, value:T):Void`
- `get(key:Int):Null`
- `exists(key:Int):Bool`
- `remove(key:Int):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():IntMap`
- `toString():String`
- `clear():Void`

### Module: haxe.PosInfos

#### PosInfos (typedef)

	`PosInfos` is a magic type which can be used to generate position information
	into the output for debugging use.

	If a function has a final optional argument of this type, i.e.
	`(..., ?pos:haxe.PosInfos)`, each call to that function which does not assign
	a value to that argument has its position added as call argument.

	This can be used to track positions of calls in e.g. a unit testing
	framework.


### Module: haxe.NativeStackTrace

#### NativeStackTrace (class)

	Do not use manually.

**Static Methods:**
- `saveStack(exception:Any):Void`
- `callStack():Any`
- `exceptionStack():Any`
- `toHaxe(nativeStackTrace:Any, ?skip:Int):Array`

### Module: haxe.Int64

#### Int64 (abstract)

	A cross-platform signed 64-bit integer.
	Int64 instances can be created from two 32-bit words using `Int64.make()`.


#### __Int64 (typedef)

	This typedef will fool `@:coreApi` into thinking that we are using
	the same underlying type, even though it might be different on
	specific platforms.


### Module: haxe.Int32

#### Int32 (abstract)

	Int32 provides a 32-bit integer with consistent overflow behavior across
	all platforms.


### Module: haxe.Exception

#### Exception (class)

	Base class for exceptions.

	If this class (or derivatives) is used to catch an exception, then
	`haxe.CallStack.exceptionStack()` will not return a stack for the exception
	caught. Use `haxe.Exception.stack` property instead:
	```haxe
	try {
		throwSomething();
	} catch(e:Exception) {
		trace(e.stack);
	}
	```

	Custom exceptions should extend this class:
	```haxe
	class MyException extends haxe.Exception {}
	//...
	throw new MyException('terrible exception');
	```

	`haxe.Exception` is also a wildcard type to catch any exception:
	```haxe
	try {
		throw 'Catch me!';
	} catch(e:haxe.Exception) {
		trace(e.message); // Output: Catch me!
	}
	```

	To rethrow an exception just throw it again.
	Haxe will try to rethrow an original native exception whenever possible.
	```haxe
	try {
		var a:Array<Int> = null;
		a.push(1); // generates target-specific null-pointer exception
	} catch(e:haxe.Exception) {
		throw e; // rethrows native exception instead of haxe.Exception
	}
	```

**Instance Methods:**
- `toString():String`
- `details():String`

### Module: haxe.EnumTools

#### EnumTools (class)

	This class provides advanced methods on enums. It is ideally used with
	`using EnumTools` and then acts as an
	  [extension](https://haxe.org/manual/lf-static-extension.html) to the
	  `enum` types.

	If the first argument to any of the methods is `null`, the result is
	unspecified.

**Static Methods:**
- `getName(e:Enum):String`
- `createByName(e:Enum, constr:String, ?params:Null):T`
- `createByIndex(e:Enum, index:Int, ?params:Null):T`
- `createAll(e:Enum):Array`
- `getConstructors(e:Enum):Array`

#### EnumValueTools (class)

	This class provides advanced methods on enum values. It is ideally used with
	`using EnumValueTools` and then acts as an
	  [extension](https://haxe.org/manual/lf-static-extension.html) to the
	  `EnumValue` types.

	If the first argument to any of the methods is `null`, the result is
	unspecified.

**Static Methods:**
- `equals(a:T, b:T):Bool`
- `getName(e:EnumValue):String`
- `getParameters(e:EnumValue):Array`
- `getIndex(e:EnumValue):Int`

### Module: haxe.Constraints

#### Constructible (abstract)

	This type unifies with any instance of classes that have a constructor
	which

	  * is `public` and
	  * unifies with the type used for type parameter `T`.

	If a type parameter `A` is assigned to a type parameter `B` which is constrained
	to `Constructible<T>`, A must be explicitly constrained to
	`Constructible<T>` as well.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### FlatEnum (abstract)

	This type unifies with an enum instance if all constructors of the enum
	require no arguments.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### Function (abstract)

	This type unifies with any function type.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### NotVoid (abstract)

	This type unifies with anything but `Void`.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


### Module: haxe.CallStack

#### CallStack (abstract)

	Get information about the call stack.


#### StackItem (enum)

	Elements return by `CallStack` methods.


### Module: Type

#### Type (class)

	The Haxe Reflection API allows retrieval of type information at runtime.

	This class complements the more lightweight Reflect class, with a focus on
	class and enum instances.

	@see https://haxe.org/manual/types.html
	@see https://haxe.org/manual/std-reflection.html

**Static Methods:**
- `getClass(o:T):Class`
- `getEnum(o:EnumValue):Enum`
- `getSuperClass(c:Class):Class`
- `getClassName(c:Class):String`
- `getEnumName(e:Enum):String`
- `resolveClass(name:String):Class`
- `resolveEnum(name:String):Enum`
- `createInstance(cl:Class, args:Array):T`
- `createEmptyInstance(cl:Class):T`
- `createEnum(e:Enum, constr:String, ?params:Null):T`
- `createEnumIndex(e:Enum, index:Int, ?params:Null):T`
- `getInstanceFields(c:Class):Array`
- `getClassFields(c:Class):Array`
- `getEnumConstructs(e:Enum):Array`
- `typeof(v:Dynamic):ValueType`
- `enumEq(a:T, b:T):Bool`
- `enumConstructor(e:EnumValue):String`
- `enumParameters(e:EnumValue):Array`
- `enumIndex(e:EnumValue):Int`
- `allEnums(e:Enum):Array`

#### ValueType (enum)

	The different possible runtime types of a value.


### Module: Sys

#### Sys (class)

	This class provides access to various base functions of system platforms.
	Look in the `sys` package for more system APIs.

**Static Methods:**
- `print(v:Dynamic):Void`
- `println(v:Dynamic):Void`
- `args():Array`
- `getEnv(s:String):String`
- `putEnv(s:String, v:Null):Void`
- `environment():Map`
- `sleep(seconds:Float):Void`
- `setTimeLocale(loc:String):Bool`
- `getCwd():String`
- `setCwd(s:String):Void`
- `systemName():String`
- `command(cmd:String, ?args:Null):Int`
- `exit(code:Int):Void`
- `time():Float`
- `cpuTime():Float`
- `executablePath():String`
- `programPath():String`
- `getChar(echo:Bool):Int`
- `stdin():Input`
- `stdout():Output`
- `stderr():Output`

### Module: String

#### String (class)

	The basic String class.

	A Haxe String is immutable, it is not possible to modify individual
	characters. No method of this class changes the state of `this` String.

	Strings can be constructed using the String literal syntax `"string value"`.

	String can be concatenated by using the `+` operator. If an operand is not a
	String, it is passed through `Std.string()` first.

	@see https://haxe.org/manual/std-String.html

**Instance Methods:**
- `toUpperCase():String`
- `toLowerCase():String`
- `charAt(index:Int):String`
- `charCodeAt(index:Int):Null`
- `indexOf(str:String, ?startIndex:Null):Int`
- `lastIndexOf(str:String, ?startIndex:Null):Int`
- `split(delimiter:String):Array`
- `substr(pos:Int, ?len:Null):String`
- `substring(startIndex:Int, ?endIndex:Null):String`
- `toString():String`
**Static Methods:**
- `fromCharCode(code:Int):String`

### Module: StdTypes

#### ArrayAccess (class)

	`ArrayAccess` is used to indicate a class that can be accessed using brackets.
	The type parameter represents the type of the elements stored.

	This interface should be used for externs only. Haxe does not support custom
	array access on classes. However, array access can be implemented for
	abstract types.

	@see https://haxe.org/manual/types-abstract-array-access.html


#### Bool (abstract)

	The standard Boolean type, which can either be `true` or `false`.

	On static targets, `null` cannot be assigned to `Bool`. If this is necessary,
	`Null<Bool>` can be used instead.

	@see https://haxe.org/manual/types-bool.html
	@see https://haxe.org/manual/types-nullability.html


#### Dynamic (abstract)

	`Dynamic` is a special type which is compatible with all other types.

	Use of `Dynamic` should be minimized as it prevents several compiler
	checks and optimizations. See `Any` type for a safer alternative for
	representing values of any type.

	@see https://haxe.org/manual/types-dynamic.html


#### Float (abstract)

	The standard `Float` type, this is a double-precision IEEE 64bit float.

	On static targets, `null` cannot be assigned to Float. If this is necessary,
	`Null<Float>` can be used instead.

	`Std.int` converts a `Float` to an `Int`, rounded towards 0.
	`Std.parseFloat` converts a `String` to a `Float`.

	@see https://haxe.org/manual/types-basic-types.html
	@see https://haxe.org/manual/types-nullability.html


#### Int (abstract)

	The standard `Int` type. Its precision depends on the platform.

	On static targets, `null` cannot be assigned to `Int`. If this is necessary,
	`Null<Int>` can be used instead.

	`Std.int` converts a `Float` to an `Int`, rounded towards 0.
	`Std.parseInt` converts a `String` to an `Int`.

	@see https://haxe.org/manual/types-basic-types.html
	@see https://haxe.org/manual/std-math-integer-math.html
	@see https://haxe.org/manual/types-nullability.html


#### Iterable (typedef)

	An `Iterable` is a data structure which has an `iterator()` method.
	See `Lambda` for generic functions on iterable structures.

	@see https://haxe.org/manual/lf-iterators.html


#### Iterator (typedef)

	An `Iterator` is a structure that permits iteration over elements of type `T`.

	Any class with matching `hasNext()` and `next()` fields is considered an `Iterator`
	and can then be used e.g. in `for`-loops. This makes it easy to implement
	custom iterators.

	@see https://haxe.org/manual/lf-iterators.html


#### KeyValueIterable (typedef)

	A `KeyValueIterable` is a data structure which has a `keyValueIterator()`
	method to iterate over key-value-pairs.


#### KeyValueIterator (typedef)

	A `KeyValueIterator` is an `Iterator` that has a key and a value.


#### Null (abstract)

	`Null<T>` is a wrapper that can be used to make the basic types `Int`,
	`Float` and `Bool` nullable on static targets.

	If null safety is enabled, only types wrapped in `Null<T>` are nullable.

	Otherwise, it has no effect on non-basic-types, but it can be useful as a way to document
	that `null` is an acceptable value for a method argument, return value or variable.

	@see https://haxe.org/manual/types-nullability.html


#### Void (abstract)

	The standard `Void` type. Only `null` values can be of the type `Void`.

	@see https://haxe.org/manual/types-void.html


### Module: Std

#### Std (class)

	The Std class provides standard methods for manipulating basic types.

**Static Methods:**
- `is(v:Dynamic, t:Dynamic):Bool`
- `isOfType(v:Dynamic, t:Dynamic):Bool`
- `downcast(value:T, c:Class):S`
- `instance(value:T, c:Class):S`
- `string(s:Dynamic):String`
- `int(x:Float):Int`
- `parseInt(x:String):Null`
- `parseFloat(x:String):Float`
- `random(x:Int):Int`

### Module: Reflect

#### Reflect (class)

	The Reflect API is a way to manipulate values dynamically through an
	abstract interface in an untyped manner. Use with care.

	@see https://haxe.org/manual/std-reflection.html

**Static Methods:**
- `hasField(o:Dynamic, field:String):Bool`
- `field(o:Dynamic, field:String):Dynamic`
- `setField(o:Dynamic, field:String, value:Dynamic):Void`
- `getProperty(o:Dynamic, field:String):Dynamic`
- `setProperty(o:Dynamic, field:String, value:Dynamic):Void`
- `callMethod(o:Dynamic, func:Function, args:Array):Dynamic`
- `fields(o:Dynamic):Array`
- `isFunction(f:Dynamic):Bool`
- `compare(a:T, b:T):Int`
- `compareMethods(f1:Dynamic, f2:Dynamic):Bool`
- `isObject(v:Dynamic):Bool`
- `isEnumValue(v:Dynamic):Bool`
- `deleteField(o:Dynamic, field:String):Bool`
- `copy(o:Null):Null`
- `makeVarArgs(f:(:Array) -> Dynamic):Dynamic`

### Module: Math

#### Math (class)

	This class defines mathematical functions and constants.

	@see https://haxe.org/manual/std-math.html

**Static Methods:**
- `abs(v:Float):Float`
- `min(a:Float, b:Float):Float`
- `max(a:Float, b:Float):Float`
- `sin(v:Float):Float`
- `cos(v:Float):Float`
- `tan(v:Float):Float`
- `asin(v:Float):Float`
- `acos(v:Float):Float`
- `atan(v:Float):Float`
- `atan2(y:Float, x:Float):Float`
- `exp(v:Float):Float`
- `log(v:Float):Float`
- `pow(v:Float, exp:Float):Float`
- `sqrt(v:Float):Float`
- `round(v:Float):Int`
- `floor(v:Float):Int`
- `ceil(v:Float):Int`
- `random():Float`
- `ffloor(v:Float):Float`
- `fceil(v:Float):Float`
- `fround(v:Float):Float`
- `isFinite(f:Float):Bool`
- `isNaN(f:Float):Bool`

### Module: Map

#### IMap (typedef)

#### Map (typedef)

### Module: EnumValue

#### EnumValue (abstract)

	An abstract type that represents any enum value.
	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-enum-instance.html


### Module: Enum

#### Enum (abstract)

	An abstract type that represents an Enum type.

	The corresponding enum instance type is `EnumValue`.

	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-enum-instance.html


### Module: Class

#### Class (abstract)

	An abstract type that represents a Class.

	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-class-instance.html


### Module: Array

#### Array (class)

	An Array is a storage for values. You can access it using indexes or
	with its API.

	@see https://haxe.org/manual/std-Array.html
	@see https://haxe.org/manual/lf-array-comprehension.html

**Instance Methods:**
- `concat(a:Array):Array`
- `join(sep:String):String`
- `pop():Null`
- `push(x:T):Int`
- `reverse():Void`
- `shift():Null`
- `slice(pos:Int, ?end:Null):Array`
- `sort(f:(:T, :T) -> Int):Void`
- `splice(pos:Int, len:Int):Array`
- `toString():String`
- `unshift(x:T):Void`
- `insert(pos:Int, x:T):Void`
- `remove(x:T):Bool`
- `contains(x:T):Bool`
- `indexOf(x:T, ?fromIndex:Null):Int`
- `lastIndexOf(x:T, ?fromIndex:Null):Int`
- `copy():Array`
- `iterator():ArrayIterator`
- `keyValueIterator():ArrayKeyValueIterator`
- `map(f:(:T) -> S):Array`
- `filter(f:(:T) -> Bool):Array`
- `resize(len:Int):Void`

### Module: Any

#### Any (abstract)

	`Any` is a type that is compatible with any other in both ways.

	This means that a value of any type can be assigned to `Any`, and
	vice-versa, a value of `Any` type can be assigned to any other type.

	It's a more type-safe alternative to `Dynamic`, because it doesn't
	support field access or operators and it's bound to monomorphs. So,
	to work with the actual value, it needs to be explicitly promoted
	to another type.



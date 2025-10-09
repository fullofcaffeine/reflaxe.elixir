# State Management Guide

> **Parent Context**: See [AGENTS.md](AGENTS.md) for compiler development context

This guide covers the comprehensive state threading system used in Reflaxe.Elixir to transform mutable state operations into immutable, functional Elixir code.

## 🎯 Overview

**State Management** is the process of transforming Haxe's mutable state patterns into Elixir's immutable, functional patterns through state threading and explicit data flow.

## 🔄 Core State Threading Pattern

### The Fundamental Transformation
```haxe
// Haxe (mutable)
class Counter {
    var count: Int = 0;
    
    function increment() {
        count++;
    }
    
    function getValue(): Int {
        return count;
    }
}

// Elixir (immutable with state threading)
defmodule Counter do
  defstruct count: 0
  
  def increment(state) do
    %{state | count: state.count + 1}
  end
  
  def get_value(state) do
    {state.count, state}
  end
end
```

## 📊 State Threading Strategies

### 1. Explicit State Passing
**Pattern**: Thread state through function parameters and return values

```haxe
// Detection pattern
function detectExplicitStatePattern(c: ClassType): Bool {
    var hasState = false;
    var hasMutators = false;
    
    for (field in c.fields.get()) {
        if (field.isVar) hasState = true;
        if (isMutatorMethod(field)) hasMutators = true;
    }
    
    return hasState && hasMutators;
}

// Transformation
function transformToStateThreading(method: ClassField): String {
    var params = extractParameters(method);
    params.insert(0, "state");  // Add state as first parameter
    
    var body = transformMethodBody(method, "state");
    var returnType = includesStateInReturn(method) ? 
        "{${method.type}, state}" : "state";
    
    return 'def ${method.name}(${params.join(", ")}) do\\n' +
           '  ${body}\\n' +
           '  ${returnType}\\n' +
           'end';
}
```

### 2. State Record Pattern
**Pattern**: Use Elixir structs/maps for state containers

```haxe
function generateStateStruct(c: ClassType): String {
    var fields = [];
    
    for (field in c.fields.get()) {
        if (field.isVar) {
            var defaultValue = getDefaultValue(field.type);
            fields.push('${field.name}: ${defaultValue}');
        }
    }
    
    return 'defstruct [${fields.join(", ")}]';
}
```

### 3. Pipeline State Threading
**Pattern**: Use pipeline operator for state transformations

```haxe
// Haxe method chaining
obj.method1().method2().method3();

// Elixir pipeline with state
state
|> method1()
|> method2()
|> method3()
```

## 🔍 Mutable Field Detection

### Field Mutability Analysis
```haxe
function analyzeMutability(c: ClassType): MutabilityInfo {
    var mutableFields = [];
    var immutableFields = [];
    
    for (field in c.fields.get()) {
        if (field.isVar && !field.isFinal) {
            mutableFields.push(field);
        } else {
            immutableFields.push(field);
        }
    }
    
    return {
        mutable: mutableFields,
        immutable: immutableFields,
        requiresStateThreading: mutableFields.length > 0
    };
}
```

### Assignment Pattern Detection
```haxe
function detectAssignmentPatterns(expr: TypedExpr): Array<Assignment> {
    var assignments = [];
    
    function traverse(e: TypedExpr) {
        switch(e.expr) {
            case TBinop(OpAssign, {expr: TField(obj, field)}, value):
                assignments.push({
                    object: obj,
                    field: field,
                    value: value,
                    requiresStateUpdate: true
                });
                
            case TUnop(OpIncrement | OpDecrement, _, {expr: TField(obj, field)}):
                assignments.push({
                    object: obj,
                    field: field,
                    value: null,  // Computed from current value
                    requiresStateUpdate: true
                });
                
            case TBlock(exprs):
                for (expr in exprs) traverse(expr);
                
            // ... other cases
        }
    }
    
    traverse(expr);
    return assignments;
}
```

## 📈 State Update Generation

### Struct Update Pattern
```haxe
function generateStructUpdate(structName: String, updates: Map<String, String>): String {
    if (updates.empty()) {
        return structName;
    }
    
    var updatePairs = [];
    for (field in updates.keys()) {
        updatePairs.push('${field}: ${updates.get(field)}');
    }
    
    return '%{${structName} | ${updatePairs.join(", ")}}';
}
```

### Nested State Updates
```haxe
function generateNestedUpdate(path: Array<String>, value: String): String {
    // Build update from innermost to outermost
    var update = value;
    
    for (i in 0...path.length) {
        var field = path[path.length - 1 - i];
        update = 'Map.put(state, :${field}, ${update})';
    }
    
    return update;
}
```

## 🧩 Method Transformation Patterns

### Getter Methods
```haxe
function transformGetter(method: ClassField): String {
    var fieldName = extractFieldFromGetter(method);
    
    return 'def get_${fieldName}(state) do\\n' +
           '  {state.${fieldName}, state}\\n' +
           'end';
}
```

### Setter Methods
```haxe
function transformSetter(method: ClassField): String {
    var fieldName = extractFieldFromSetter(method);
    var paramName = method.params[0].name;
    
    return 'def set_${fieldName}(state, ${paramName}) do\\n' +
           '  %{state | ${fieldName}: ${paramName}}\\n' +
           'end';
}
```

### Complex State Mutations
```haxe
function transformComplexMutation(method: ClassField): String {
    var stateUpdates = analyzeStateChanges(method);
    var operations = [];
    
    for (update in stateUpdates) {
        operations.push(generateUpdateOperation(update));
    }
    
    // Chain updates
    return 'def ${method.name}(state, ${extractParams(method)}) do\\n' +
           '  state\\n' +
           operations.map(op -> '  |> ${op}').join('\\n') + '\\n' +
           'end';
}
```

## ⚡ LiveView State Management

### Socket State Pattern
```haxe
function transformLiveViewState(c: ClassType): String {
    var assigns = extractAssigns(c);
    
    return assigns.map(assign -> {
        'socket |> assign(:${assign.name}, ${assign.defaultValue})';
    }).join('\\n');
}
```

### Event Handler State Updates
```haxe
function transformEventHandler(handler: ClassField): String {
    var event = extractEventName(handler);
    var stateUpdates = analyzeSocketUpdates(handler);
    
    return 'def handle_event("${event}", params, socket) do\\n' +
           '  socket = socket\\n' +
           stateUpdates.map(u -> '    |> ${u}').join('\\n') + '\\n' +
           '  {:noreply, socket}\\n' +
           'end';
}
```

## 📊 GenServer State Management

### State Initialization
```haxe
function generateInit(c: ClassType): String {
    var initialState = generateInitialState(c);
    
    return 'def init(_args) do\\n' +
           '  {:ok, ${initialState}}\\n' +
           'end';
}
```

### Call Handler Pattern
```haxe
function generateCallHandler(method: ClassField): String {
    var methodName = method.name;
    var stateParam = "state";
    var result = transformMethodBody(method, stateParam);
    
    return 'def handle_call({:${methodName}, args}, _from, ${stateParam}) do\\n' +
           '  {result, new_state} = ${result}\\n' +
           '  {:reply, result, new_state}\\n' +
           'end';
}
```

## 🧪 State Management Testing

### State Threading Verification
```haxe
class StateThreadingTest {
    static function testSimpleUpdate() {
        var input = "state.count = state.count + 1";
        var output = transformToStateUpdate(input);
        assert(output == "%{state | count: state.count + 1}");
    }
    
    static function testChainedUpdates() {
        var input = parseClass("
            class Counter {
                var count: Int = 0;
                var total: Int = 0;
                
                function increment() {
                    count++;
                    total += count;
                }
            }
        ");
        
        var output = transformClass(input);
        assert(output.contains("|>"));  // Uses pipeline
        assert(output.contains("%{state |"));  // Uses struct update
    }
}
```

### Debug Tracing
```haxe
#if debug_state_management
function traceStateTransformation(before: String, after: String) {
    trace('[StateManagement] === TRANSFORMATION ===');
    trace('[StateManagement] Before: ${before}');
    trace('[StateManagement] After: ${after}');
    trace('[StateManagement] =======================');
}
#end
```

## 🔧 Integration Guidelines

### Compiler Integration
```haxe
// In ElixirCompiler.hx
override function compileClass(c: ClassType, fields: Array<String>): String {
    if (requiresStateThreading(c)) {
        return stateManagementCompiler.compileStatefulClass(c, fields);
    } else {
        return super.compileClass(c, fields);
    }
}
```

### Detection Heuristics
```haxe
function requiresStateThreading(c: ClassType): Bool {
    // Check for mutable fields
    if (hasMutableFields(c)) return true;
    
    // Check for specific annotations
    if (c.meta.has(":stateful")) return true;
    if (c.meta.has(":liveview")) return true;
    if (c.meta.has(":genserver")) return true;
    
    // Check for state-modifying methods
    return hasStateMutators(c);
}
```

## 📚 Best Practices

### State Threading Rules
1. **Always return updated state** from mutating functions
2. **Thread state explicitly** through all function calls
3. **Use structs** for complex state containers
4. **Leverage pipelines** for sequential updates
5. **Avoid hidden state** - make all state visible

### Performance Considerations
- **Minimize state copying** by using efficient update patterns
- **Batch updates** when possible
- **Use ETS/Agents** for truly shared state
- **Profile state-heavy code** for bottlenecks

## 📚 Related Documentation

- **[StateManagementCompiler.hx](../../src/reflaxe/elixir/helpers/StateManagementCompiler.hx)** - Implementation
- **[STATE_THREADING_TRANSFORMATION.md](STATE_THREADING_TRANSFORMATION.md)** - Detailed patterns
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - State in compilation
- **[DEBUG_XRAY_SYSTEM.md](DEBUG_XRAY_SYSTEM.md)** - Debugging state transformations

---

This guide provides comprehensive coverage of state management transformation in Reflaxe.Elixir. The goal is preserving Haxe's imperative semantics while generating idiomatic, functional Elixir code.
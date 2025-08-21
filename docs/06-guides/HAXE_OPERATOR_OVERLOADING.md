# Haxe Operator Overloading Guide for Reflaxe.Elixir

This guide documents the lessons learned while implementing type-safe abstractions for Phoenix externs, specifically focusing on operator overloading patterns in Haxe abstracts.

## 🚨 Critical Lessons Learned

### ❌ What DOESN'T Work in Haxe Abstracts

#### 1. Generic Field Access with @:op(a.b)
```haxe
// ❌ WRONG - Compilation Error: "Second argument type must be String"
@:op(a.b) public function getField<K>(field: K): Dynamic {
    return Reflect.field(this, cast field);
}
```
**Problem**: The `@:op(a.b)` metadata requires the field parameter to be String, not generic.

#### 2. Field Assignment with @:op(a.b = c)
```haxe
// ❌ WRONG - Compilation Error: "Assignment overloading is not supported"
@:op(a.b = c) public function setField<K, V>(field: K, value: V): V {
    Reflect.setField(this, cast field, value);
    return value;
}
```
**Problem**: Haxe doesn't support assignment operator overloading with this syntax.

### ✅ What DOES Work in Haxe Abstracts

#### 1. Array Access with @:arrayAccess
```haxe
// ✅ CORRECT - Reading: assigns["field"]
@:arrayAccess
public inline function get(key: String): Dynamic {
    return Reflect.field(this, key);
}

// ✅ CORRECT - Writing: assigns["field"] = value
@:arrayAccess
public inline function set<V>(key: String, value: V): V {
    Reflect.setField(this, key, value);
    return value;
}
```

**Benefits**:
- Enables ergonomic `assigns["field"]` syntax
- Follows standard library patterns (Map, DynamicAccess)
- Compiles successfully on all targets
- Provides type safety for keys (String)

#### 2. Dynamic Field Resolution with @:resolve
```haxe
// ✅ CORRECT - For dynamic field access like assigns.field
@:resolve
private inline function resolve(name: String): Dynamic {
    return Reflect.field(this, name);
}
```

**Note**: `@:resolve` is mainly for read access and conflicts with `@:forward`.

## 📚 Standard Library Patterns

### DynamicAccess Pattern (Recommended)
Our implementation follows `haxe.DynamicAccess` exactly:

```haxe
abstract Assigns<T>(Dynamic) from Dynamic to Dynamic {
    @:arrayAccess
    public inline function get(key: String): Dynamic {
        return Reflect.field(this, key);
    }
    
    @:arrayAccess
    public inline function set<V>(key: String, value: V): V {
        Reflect.setField(this, key, value);
        return value;
    }
}
```

### Map Pattern
Similar to how `haxe.ds.Map` uses `@:arrayAccess`:

```haxe
// From Map.hx
@:arrayAccess public inline function get(key:K)
    return this.get(key);
```

## 🎯 Implementation Guidelines

### 1. Choose the Right Pattern
- **@:arrayAccess**: For map-like or collection-like access (`obj["key"]`)
- **@:resolve**: For field-like access (`obj.field`) - use sparingly
- **Regular methods**: When operator overloading isn't needed

### 2. Follow Standard Library Conventions
- Use `inline` for performance-critical operators
- Match parameter and return types to standard library
- Provide both array access and method alternatives

### 3. Documentation Strategy
```haxe
/**
 * Array-style field access (Reading)
 * 
 * Enables syntax: assigns["field"] for type-safe field access
 * Following the same pattern as haxe.DynamicAccess and Map
 * 
 * @param key Field name to access
 * @return Dynamic Field value, null if not present
 */
@:arrayAccess
public inline function get(key: String): Dynamic {
    return Reflect.field(this, key);
}
```

## 🔧 Available Operator Overloads

### Supported Operators
From the [Haxe Manual](https://haxe.org/manual/types-abstract-operator-overloading.html):

- **Binary operators**: `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`, `<<`, `>>`, `>>>`
- **Unary operators**: `++`, `--`, `!`, `-`, `+`
- **Comparison**: `<`, `<=`, `>`, `>=`, `==`, `!=`
- **Array access**: `@:arrayAccess` for `[]` operations
- **Function calls**: `@:op(a())` (Haxe 4.3+)

### @:arrayAccess Signatures
```haxe
// Reading: obj[key]
@:arrayAccess
function get(key: KeyType): ValueType

// Writing: obj[key] = value
@:arrayAccess  
function set(key: KeyType, value: ValueType): ValueType
```

## 🚨 Common Pitfalls

### 1. Don't Use @:op(a.b) for Dynamic Access
```haxe
// ❌ WRONG - Limited and error-prone
@:op(a.b) function getField(field: String): Dynamic

// ✅ BETTER - Use @:arrayAccess
@:arrayAccess function get(key: String): Dynamic
```

### 2. Conflicts with @:forward
```haxe
// ❌ PROBLEM - @:forward overrides @:resolve
@:forward
@:resolve  // This won't work as expected
abstract MyAbstract(SomeType) { ... }
```

### 3. Performance Considerations
```haxe
// ✅ GOOD - Always use inline for operators
@:arrayAccess
public inline function get(key: String): Dynamic
```

## 📖 Usage Examples

### Basic Usage
```haxe
typedef UserAssigns = {
    name: String,
    email: String,
    age: Int
}

var assigns: Assigns<UserAssigns> = Assigns.fromObject({
    name: "John",
    email: "john@example.com",
    age: 30
});

// Array access syntax (preferred)
var userName = assigns["name"];
assigns["age"] = 31;

// Method syntax (alternative)
var userEmail = assigns.getField("email");
assigns.setField("name", "Jane");
```

### In Phoenix Templates
```haxe
function render(assigns: Assigns<UserPageAssigns>): String {
    return HXX.hxx('
        <div>
            <h1>Welcome ${assigns["user"]["name"]}</h1>
            <p>Age: ${assigns["user"]["age"]}</p>
        </div>
    ');
}
```

## 🔗 References

- [Haxe Abstract Types Manual](https://haxe.org/manual/types-abstract.html)
- [Haxe Operator Overloading Manual](https://haxe.org/manual/types-abstract-operator-overloading.html)
- [DynamicAccess Source Code](https://github.com/HaxeFoundation/haxe/blob/development/std/haxe/DynamicAccess.hx)
- [Map Source Code](https://github.com/HaxeFoundation/haxe/blob/development/std/haxe/ds/Map.hx)

## 💡 Key Takeaways

1. **@:arrayAccess is the preferred pattern** for dynamic field access in abstracts
2. **Follow standard library conventions** - use the same patterns as Map and DynamicAccess  
3. **Provide both operator and method syntax** for maximum flexibility
4. **Always document the intended usage** with clear examples
5. **Test compilation early and often** when implementing operator overloading
6. **Use inline for performance** on frequently-called operators

This approach gives us type-safe, ergonomic field access while maintaining compatibility with Phoenix's Dynamic-based APIs.
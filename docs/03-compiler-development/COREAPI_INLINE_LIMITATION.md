# @:coreApi Classes and Inline Limitation

## The Issue

When using `@:coreApi` classes (like our custom Array implementation), we cannot use `inline` on methods that contain `untyped __elixir__()` calls.

## Why This Happens

1. **@:coreApi replaces built-in types globally** - Our Array class replaces Haxe's built-in Array everywhere, including in Haxe's standard library files.

2. **Standard library uses inline** - Files like `haxe/CallStack.hx` have inline methods that call Array methods:
   ```haxe
   // In CallStack.hx
   public inline function copy():CallStack {
       return this.copy(); // CallStack is abstract over Array
   }
   ```

3. **Inline expansion happens before Reflaxe** - When both CallStack.copy() and Array.copy() are inline, Haxe tries to expand Array.copy()'s `__elixir__()` call into CallStack's context.

4. **__elixir__ doesn't exist in that context** - CallStack.hx is compiled by Haxe itself, not by Reflaxe, so the `__elixir__` identifier isn't available there.

## The Solution

Don't use `inline` on methods in `@:coreApi` classes that use `__elixir__()`. The performance impact is minimal since:
- The Elixir compiler can still optimize these calls
- Most of these methods are simple delegations to native functions
- The AST transformer can still optimize patterns at a higher level

## Alternative Approaches

For methods that don't use `__elixir__()`, inline is fine:
```haxe
// ✅ OK - No __elixir__ usage
public inline function iterator(): haxe.iterators.ArrayIterator<T> {
    return new haxe.iterators.ArrayIterator(this);
}

// ❌ PROBLEMATIC - Uses __elixir__
public inline function copy(): Array<T> {
    return untyped __elixir__("{0}", this);
}
```

## Future Improvements

This could potentially be fixed by:
1. Having Reflaxe inject `__elixir__` earlier in the compilation pipeline
2. Using a different mechanism than `untyped` for target injection
3. Providing a macro-based solution that works with inline

For now, the limitation is documented and the workaround (not using inline) has minimal impact.
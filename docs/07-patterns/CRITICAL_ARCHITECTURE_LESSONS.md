# ⚠️ CRITICAL ARCHITECTURE LESSONS - NEVER REPEAT THESE MISTAKES

## Lesson #1: ALWAYS Generate Idiomatic Target Code

### The Mistake (What NOT to Do)
```haxe
// ❌ WRONG: Reimplementing platform features in pure Haxe
public function getDay(): Int {
    // Implementation of Zeller's congruence algorithm
    var year = getFullYear();
    var month = getMonth() + 1;
    // ... 20 lines of manual date calculations ...
}
```

### The Correct Approach
```haxe
// ✅ CORRECT: Use the target platform's native capabilities
public function getDay(): Int {
    // Use Elixir's excellent DateTime library
    return untyped __elixir__("Date.day_of_week(...)");
}
```

### Why This Matters
1. **Elixir has excellent date/time libraries** - Why reimplement them poorly?
2. **Generated code should look native** - An Elixir developer should see familiar patterns
3. **Performance** - Native implementations are optimized
4. **Correctness** - Platform libraries handle edge cases, timezones, leap years, etc.
5. **Maintenance** - Less code to maintain when using platform features

## Lesson #2: The Point of Reflaxe is NOT to Force Haxe Everywhere

### The Fundamental Philosophy

**WRONG Understanding:**
"We need to implement everything in pure Haxe to ensure it works"

**CORRECT Understanding:**
"We provide a consistent Haxe API that compiles to the BEST implementation for each target"

### What This Means in Practice

```haxe
// The Haxe API (consistent across all targets)
class Date {
    public function getTime(): Float;
    public function getDay(): Int;
}

// When compiled to Elixir:
defmodule Date do
    def get_time(), do: DateTime.to_unix(...) # Uses Elixir DateTime
    def get_day(), do: Date.day_of_week(...)  # Uses Elixir Date
end

// When compiled to JavaScript:
class Date {
    getTime() { return jsDate.getTime(); }    // Uses JS Date
    getDay() { return jsDate.getDay(); }      // Uses JS Date
}

// When compiled to Python:
class Date:
    def get_time(self): return datetime.timestamp()  # Uses Python datetime
    def get_day(self): return datetime.weekday()    # Uses Python datetime
```

## Lesson #3: When to Use Pure Haxe vs Platform Features

### Use Pure Haxe When:
- **The logic doesn't exist in the target platform** (custom business logic)
- **You need identical behavior across all targets** (specific algorithms)
- **The platform implementation is buggy or incomplete**

### Use Platform Features When:
- **The platform has excellent implementations** (DateTime, String, etc.)
- **You want idiomatic output** (ALWAYS for standard library)
- **Performance matters** (native implementations are optimized)
- **The platform handles complexity better** (timezones, localization, etc.)

## Lesson #4: `untyped __elixir__()` is NOT a Workaround

### Wrong Thinking
"We should avoid `untyped __elixir__()` because it's a hack"

### Correct Thinking
"`untyped __elixir__()` is the correct tool for generating idiomatic Elixir code when externs don't work"

### When to Use It
```haxe
// ✅ CORRECT: Generate idiomatic Elixir
public static function now(): Date {
    return untyped __elixir__("DateTime.utc_now()");
}

// ❌ WRONG: Reimplement in Haxe
public static function now(): Date {
    // 50 lines of manual timestamp calculation
}
```

## Lesson #5: The Standard Library MUST Generate Idiomatic Code

### The Golden Rule
**The standard library sets the quality bar for all generated code.**

If our Date class generates:
```elixir
# ❌ BAD: Non-idiomatic Elixir
def get_day() do
    # 30 lines of manual calculations
    year = div(timestamp, 31536000000)
    # ... complex math ...
end
```

Instead of:
```elixir
# ✅ GOOD: Idiomatic Elixir
def get_day() do
    Date.day_of_week(@date)
end
```

Then we've failed at our core mission.

## Lesson #6: Cross-Platform != Lowest Common Denominator

### Wrong Approach
"To be cross-platform, we must only use features available on ALL platforms"

### Correct Approach
"To be cross-platform, we provide a consistent API that uses the BEST features of EACH platform"

```haxe
class FileSystem {
    #if elixir
    // Use Elixir's File module
    public static function exists(path: String): Bool {
        return untyped __elixir__("File.exists?({0})", path);
    }
    #elseif nodejs
    // Use Node's fs module
    public static function exists(path: String): Bool {
        return js.node.Fs.existsSync(path);
    }
    #elseif sys
    // Use Haxe's sys API
    public static function exists(path: String): Bool {
        return sys.FileSystem.exists(path);
    }
    #end
}
```

## The Architecture Trap We Fell Into

### What Happened
1. Started with "we can't get externs to work"
2. Jumped to "let's avoid Elixir features entirely"
3. Ended up reimplementing date math in Haxe
4. Lost sight of the goal: **idiomatic Elixir output**

### How to Avoid It
1. **ALWAYS ask**: "What would an Elixir developer write?"
2. **NEVER reimplement** what the platform provides well
3. **USE `untyped __elixir__()`** when externs fail - it's the right tool
4. **REMEMBER the goal**: Idiomatic code for each target

## Critical Reminders for Standard Library Development

### ✅ DO
- Generate code that looks hand-written by platform experts
- Use platform libraries for their intended purpose
- Leverage each platform's strengths
- Use `untyped __elixir__()` for idiomatic output

### ❌ DON'T
- Reimplement platform features in pure Haxe
- Avoid platform capabilities to be "pure"
- Generate non-idiomatic code
- Think of `untyped __elixir__()` as a hack

## The Ultimate Test

Before implementing ANYTHING in the standard library, ask:

> "If an experienced Elixir developer saw the generated code, would they think it was written by another experienced Elixir developer?"

If the answer is NO, you're doing it wrong.

## Summary: The Core Philosophy

**Reflaxe.Elixir exists to let developers write Haxe that compiles to Elixir code that looks like it was written by Elixir experts.**

Not to force Haxe implementations where Elixir already excels.
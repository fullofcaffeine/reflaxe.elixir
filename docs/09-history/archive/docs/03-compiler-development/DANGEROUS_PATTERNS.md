# ⚠️ Dangerous Patterns to Avoid in Compiler Development

## 🚫 CRITICAL: String Concatenation in Macro Blocks

### The Problem
**Haxe compiler bug**: String concatenation operations in macro-conditional blocks cause infinite hangs when output is redirected.

### Dangerous Patterns (NEVER USE)

#### ❌ String Concatenation with + Operator
```haxe
#if (macro || reflaxe_runtime)
class Dangerous {
    function build(): String {
        // ❌ NEVER DO THIS - Causes hang
        return 'part1' + 'part2' + 'part3';
        
        // ❌ ALSO DANGEROUS
        var result = '';
        result = result + 'line1\n';
        result = result + 'line2\n';
        
        // ❌ += IS ALSO FORBIDDEN
        var output = '';
        output += 'content';
        
        return result;
    }
}
#end
```

#### ❌ StringBuf Operations
```haxe
#if (macro || reflaxe_runtime)
class AlsoDangerous {
    function build(): String {
        // ❌ NEVER USE StringBuf in macro blocks
        var sb = new StringBuf();
        sb.add('line1\n');
        sb.add('line2\n');
        return sb.toString();
    }
}
#end
```

### Safe Patterns (ALWAYS USE)

#### ✅ Array Join Pattern
```haxe
#if (macro || reflaxe_runtime)
class Safe {
    function build(): String {
        // ✅ SAFE: Array join pattern
        var lines = [
            'defmodule MyModule do',
            '  def my_function do',
            '    :ok',
            '  end',
            'end'
        ];
        return lines.join('\n');
    }
    
    function buildDynamic(items: Array<String>): String {
        // ✅ SAFE: Building array then joining
        var parts = [];
        for (item in items) {
            parts.push('  add :${item}, :string');
        }
        return parts.join('\n');
    }
}
#end
```

#### ✅ Single String Literals
```haxe
#if (macro || reflaxe_runtime)
class AlsoSafe {
    function build(): String {
        // ✅ SAFE: Single string literal (no concatenation)
        return 'defmodule Test do\n  def test, do: :ok\nend';
    }
}
#end
```

### How to Detect Dangerous Patterns

#### Grep Commands to Find Problems
```bash
# Find string concatenation in macro blocks
grep -r "^#if.*macro" src/ -A 100 | grep -E "(\+.*['\"]|['\"].*\+)"

# Find StringBuf usage in macro blocks
grep -r "^#if.*macro" src/ -A 100 | grep "new StringBuf"

# Find += operations with strings
grep -r "^#if.*macro" src/ -A 100 | grep "+="
```

### Why This Happens
- **Trigger conditions**:
  1. Code is in `#if (macro || reflaxe_runtime)` block
  2. Uses string concatenation (`+`) or StringBuf
  3. Compilation output is redirected (`> /dev/null 2>&1`)
- **Result**: Haxe compiler hangs indefinitely
- **Affected environments**: Test runners, CI pipelines, Make-based builds

### Historical Context
- **Discovered**: August 27, 2025
- **Investigation time**: 5+ hours
- **Files affected**: MigrationDSL.hx
- **Solution applied**: MigrationDSLFixed.hx using array join pattern
- **Full report**: [/docs/09-history/2025-08-27-migration-dsl-hang-retrospective.md](/docs/09-history/2025-08-27-migration-dsl-hang-retrospective.md)

### Enforcement Checklist
Before committing any changes to macro code:
- [ ] No `+` operator with strings in macro blocks
- [ ] No `StringBuf` usage in macro blocks
- [ ] No `+=` operator with strings in macro blocks
- [ ] All multi-line strings use array join pattern
- [ ] Test with `npm test` (uses output redirection)

### If You Find This Pattern
1. **Don't ignore it** - It WILL cause CI failures
2. **Refactor immediately** - Use array join pattern
3. **Test thoroughly** - Run `npm test` to verify
4. **Document the change** - Note why refactoring was needed

---

**Remember**: This is not a style preference - it's a hard requirement to prevent compiler hangs.
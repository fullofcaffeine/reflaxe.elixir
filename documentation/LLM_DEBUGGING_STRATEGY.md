# LLM Agent Debugging Strategy: Two-Level Abstraction Awareness

## Critical Concept for LLM Agents

**Reflaxe.Elixir involves TWO abstraction levels that agents MUST understand for effective debugging:**

```
SOURCE LEVEL (Haxe)     →     TARGET LEVEL (Elixir)
─────────────────────          ─────────────────────
User.hx                 →      User.ex
Post.hx                 →      Post.ex  
UserLive.hx             →      UserLive.ex
```

**Key Insight**: Errors can occur at EITHER level, and debugging requires knowing WHICH level to inspect.

## Debugging Decision Matrix for LLM Agents

### **Debug at HAXE Level (.hx files)** when:
- ✅ **Compilation errors**: "Type not found", "Syntax error", "Missing annotation"
- ✅ **Type system issues**: "Cannot assign String to Int", "Missing import"  
- ✅ **Annotation problems**: "@:liveview annotation invalid", "@:changeset validation failed"
- ✅ **Haxe syntax issues**: Missing semicolons, incorrect function signatures

**Example Error → Action**:
```
Error: "Type 'UnknownType' not found"
→ Debug in SOURCE (User.hx): Add import or fix type name
```

### **Debug at ELIXIR Level (.ex files)** when:
- ✅ **Runtime errors**: Phoenix crashes, Ecto query failures, GenServer crashes
- ✅ **Integration issues**: "Module not found", Phoenix routing problems
- ✅ **BEAM-specific errors**: Pattern match failures, process crashes
- ✅ **Generated code problems**: Inspect what Reflaxe actually produced

**Example Error → Action**:
```
Error: "(RuntimeError) no function clause matching in UserLive.handle_event/3"  
→ Debug in TARGET (UserLive.ex): Check generated handle_event function structure
```

## Current Problem: Abstraction Blind Spots ❌

### **What LLM Agents Currently Don't Know**:
1. **Error source level**: Is this a Haxe compilation error or Elixir runtime error?
2. **File mapping**: Which .hx file generated which .ex file?
3. **Generated code inspection**: How to view compiled output when debugging runtime issues?
4. **Compilation success vs runtime failure**: Did Haxe→Elixir work, but Elixir code has issues?

### **Problematic Scenarios**:
```bash
# Scenario 1: Agent gets Elixir runtime error
** (RuntimeError) function UserLive.handle_event/3 is undefined

# Agent might incorrectly debug in User.hx instead of checking UserLive.ex
# Agent doesn't know: Did compilation succeed but generate wrong code?
```

## Enhanced LLM Debugging Workflow (Proposed)

### **Phase 1: Error Classification** 
```bash
# Enhanced error reporting with abstraction level
mix haxe.status --format json
{
  "compilation": {
    "success": false,
    "level": "haxe",  // "haxe" or "elixir" or "mix"
    "error": "Type 'UnknownType' not found in User.hx:23"
  }
}
```

### **Phase 2: Source-Target Mapping**
```bash  
# Show which .hx files map to which .ex files
mix haxe.mapping --format json
{
  "source_target_map": {
    "src_haxe/User.hx": "lib/User.ex",
    "src_haxe/UserLive.hx": "lib/UserLive.ex"
  },
  "compilation_status": {
    "User.hx": {"compiled": true, "target_exists": true},
    "UserLive.hx": {"compiled": false, "error": "Type error at line 15"}
  }
}
```

### **Phase 3: Generated Code Inspection**
```bash
# View generated Elixir code for debugging
mix haxe.inspect UserLive.hx
# Shows both source Haxe and generated Elixir side-by-side

mix haxe.diff User.hx
# Shows what changed in generated .ex after .hx modification
```

### **Phase 4: Abstraction-Aware Error Messages**
```bash
# Current (confusing):
Error: function UserLive.handle_event/3 is undefined

# Enhanced (abstraction-aware):
[ELIXIR RUNTIME ERROR] function UserLive.handle_event/3 is undefined
Source: UserLive.hx compiled successfully to UserLive.ex
Suggestion: Check generated UserLive.ex - method may not have been generated correctly
Debug Level: ELIXIR (inspect generated code)
```

## LLM Agent Debugging Playbook

### **Step 1: Identify Error Abstraction Level**
```bash
# Always check compilation status first
mix haxe.status --format json

# If compilation.success = false → Debug at HAXE level
# If compilation.success = true but runtime error → Debug at ELIXIR level
```

### **Step 2: Use Appropriate Debugging Tools**

**For HAXE-level issues**:
```bash
# Fix source code directly
vim src_haxe/User.hx  # Add missing imports, fix types, etc.
# File watcher auto-recompiles
```

**For ELIXIR-level issues**:
```bash
# Inspect generated code
mix haxe.inspect User.hx
# Compare with expected Elixir patterns
# May indicate Reflaxe compiler bug or incorrect Haxe patterns
```

### **Step 3: Cross-Reference Between Levels**
```bash
# When runtime error occurs:
# 1. Confirm Haxe compilation succeeded
# 2. Inspect generated Elixir code  
# 3. Compare generated code with expected Phoenix/Ecto patterns
# 4. Fix at appropriate level (source .hx or report compiler bug)
```

## Implementation Priorities for LLM Agent Support

### **HIGH PRIORITY** (Next Release):
- [ ] **Error level classification**: Tag errors as "haxe", "elixir", or "mix" level
- [ ] **Source-target mapping API**: Show which .hx → .ex compilations  
- [ ] **Generated code inspection**: `mix haxe.inspect <file>` command
- [ ] **Abstraction-aware error messages**: Clear indication of debug level needed

### **MEDIUM PRIORITY**:
- [ ] **Side-by-side comparison**: Source .hx vs generated .ex viewing
- [ ] **Compilation success tracking**: Per-file compilation status
- [ ] **Runtime error source mapping**: Link Elixir errors back to Haxe source
- [ ] **Debug level recommendations**: Auto-suggest whether to debug at Haxe or Elixir level

### **LOW PRIORITY** (Advanced):
- [ ] **Source maps**: Full line-level mapping between .hx and .ex
- [ ] **Interactive debugging**: Step through Haxe source while debugging Elixir runtime
- [ ] **Compiler introspection**: Show compilation decision-making process

## Enhanced LLM Agent Workflow Example

```bash
# LLM Agent encounters error:
** (RuntimeError) no function clause matching in UserLive.handle_event/3

# Step 1: Check abstraction level
mix haxe.status --format json
# Response: {"compilation": {"success": true}, "level": "mix"}
# → This is an ELIXIR runtime error, not Haxe compilation error

# Step 2: Inspect generated code
mix haxe.inspect UserLive.hx
# Shows: Haxe source + generated Elixir side-by-side
# Agent sees: handle_event function was generated, but with wrong pattern

# Step 3: Debug at correct level
# Agent identifies: Generated Elixir code has pattern mismatch
# Agent fixes: SOURCE Haxe code (UserLive.hx) to generate correct pattern
# File watcher: Auto-recompiles, problem resolved

# Without abstraction awareness: Agent might have wasted time 
# debugging Elixir files that get overwritten on next compilation!
```

## Critical Documentation for LLM Agents

### **Rule 1: Never Edit Generated .ex Files**
- Generated Elixir files are **OVERWRITTEN** on every compilation
- Always fix issues in SOURCE .hx files  
- Only inspect .ex files for debugging, never modify them

### **Rule 2: Error Classification Strategy**
```
Compilation fails → Debug HAXE level (.hx files)
Compilation succeeds but runtime error → Debug ELIXIR level (inspect .ex, fix .hx)
Mix/Phoenix integration issues → Debug MIX level (project config, dependencies)
```

### **Rule 3: Use Inspection Tools**
- `mix haxe.inspect File.hx` → See generated code without editing
- `mix haxe.mapping` → Understand which files affect which outputs
- `mix haxe.status` → Know current compilation state before debugging

## Conclusion

**The dual abstraction level is CRITICAL for LLM agent success with Reflaxe.Elixir.**

**Current Gap**: Agents don't know which level to debug at, leading to:
- Wasted time debugging wrong abstraction level
- Editing generated files that get overwritten
- Confusion about error sources

**Solution**: Enhanced tooling with:
- ✅ **Error level classification** (haxe/elixir/mix)  
- ✅ **Generated code inspection tools**
- ✅ **Source-target mapping visibility**
- ✅ **Abstraction-aware error messages**

**Result**: LLM agents can debug efficiently by knowing WHETHER to look at Haxe source or Elixir output, and have tools to inspect both levels effectively.
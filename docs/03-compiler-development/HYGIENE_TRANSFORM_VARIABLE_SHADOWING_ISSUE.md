# HygieneTransforms tempVarRenameMap Investigation - Complete Audit

## Investigation Date
September 30, 2025

## Executive Summary
Complete audit of all `context.tempVarRenameMap.set()` calls to prepare for dual-key storage implementation. Found 11 active locations across 5 files with MIXED key formats (ID-based and name-based). Identified 5 locations requiring modification for dual-key storage.

## Key Format Analysis

### Pattern 1: ID-BASED KEYS (most common)
- **Format**: `Std.string(v.id)` or `Std.string(arg.v.id)`
- **Example**: "57694" (numeric AST node ID)
- **Usage**: Function parameters, TVar expressions
- **Purpose**: Track variables across AST transformations

### Pattern 2: NAME-BASED KEYS (gold standard)
- **Format**: `v.name` (actual variable name string)
- **Example**: "changeset" (the variable identifier)
- **Usage**: Infrastructure variable extraction
- **Purpose**: Enable EVar reference renaming
- **✅ THIS IS WHAT WE NEED EVERYWHERE**

### Pattern 3: CONTEXT MANAGEMENT (infrastructure)
- **Format**: Copies all keys from source map
- **Purpose**: Merge contexts, preserve mappings

## Complete Location Inventory

### 1. ElixirCompiler.hx:1515 ⚠️ NEEDS DUAL-KEY
**Location**: Function parameter processing
**Phase**: Builder
**Key Format**: ID-BASED - `idKey = Std.string(arg.v.id)`
**Value**: `finalName` (with underscore if unused)
**Code Context**:
```haxe
Line 1475: var idKey = Std.string(arg.v.id);
Line 1514: if (!context.tempVarRenameMap.exists(idKey)) {
Line 1515:     context.tempVarRenameMap.set(idKey, finalName);
Line 1516: }
```
**Action Required**: Add name-based key alongside ID-based key

---

### 2. CompilationContext.hx:351 ✅ INFRASTRUCTURE
**Location**: `mergeChild()` method
**Phase**: Context management
**Key Format**: INHERITED (preserves all keys from child)
**Purpose**: Merge child context into parent
**Code Context**:
```haxe
Line 349: for (key in child.tempVarRenameMap.keys()) {
Line 350:     var value = child.tempVarRenameMap.get(key);
Line 351:     tempVarRenameMap.set(key, value);
Line 352: }
```
**Action Required**: NONE - already preserves all keys

---

### 3. CompilationContext.hx:427 🔍 PUBLIC API
**Location**: `registerTempVarRename()` method
**Phase**: Public API
**Key Format**: FLEXIBLE (depends on caller)
**Purpose**: External API for registering renames
**Code Context**:
```haxe
Line 426: public function registerTempVarRename(tempName: String, newName: String): Void {
Line 427:     tempVarRenameMap.set(tempName, newName);
Line 428: }
```
**Action Required**: Audit callers of this method

---

### 4. VariableBuilder.hx:161 ✅ GOLD STANDARD
**Location**: Infrastructure variable extraction
**Phase**: Builder
**Key Format**: NAME-BASED - `v.name` ✅
**Value**: `extractedVarName`
**Code Context**:
```haxe
Line 158: if (context.tempVarRenameMap == null) {
Line 159:     context.tempVarRenameMap = new Map<String, String>();
Line 160: }
Line 161: context.tempVarRenameMap.set(v.name, extractedVarName);
```
**Comment in source**: "Store mapping for later use"
**Action Required**: NONE - ✅ ALREADY PERFECT (uses name-based key)

---

### 5. FunctionBuilder.hx:86 ✅ INFRASTRUCTURE
**Location**: Function scope context initialization
**Phase**: Builder (function scope setup)
**Key Format**: INHERITED (copies all from old context)
**Purpose**: Create new function scope preserving parent mappings
**Code Context**:
```haxe
Line 83: var oldTempVarRenameMap = context.tempVarRenameMap;
Line 84: context.tempVarRenameMap = new Map();
Line 85: for (key in oldTempVarRenameMap.keys()) {
Line 86:     context.tempVarRenameMap.set(key, oldTempVarRenameMap.get(key));
Line 87: }
```
**Action Required**: NONE - preserves all keys

---

### 6. FunctionBuilder.hx:190 ⚠️ NEEDS DUAL-KEY
**Location**: Function parameter registration
**Phase**: Builder
**Key Format**: ID-BASED - `idKey = Std.string(arg.v.id)`
**Value**: `finalName` (with underscore if unused)
**Code Context**:
```haxe
Line 154: var idKey = Std.string(arg.v.id);
Line 189: if (!context.tempVarRenameMap.exists(idKey)) {
Line 190:     context.tempVarRenameMap.set(idKey, finalName);
Line 191: }
```
**Action Required**: Add name-based key alongside ID-based key

---

### 7. ElixirASTBuilder.hx:560 ✅ GOLD STANDARD
**Location**: Infrastructure variable extraction
**Phase**: Builder
**Key Format**: NAME-BASED - `v.name` ✅
**Value**: `extractedVarName`
**Code Context**:
```haxe
Line 555: // CRITICAL: Use variable NAME as key, not ID, since Haxe creates different IDs for the same variable
Line 559: // Map the infrastructure variable name to the extracted variable name
Line 560: currentContext.tempVarRenameMap.set(v.name, extractedVarName);
```
**Comment in source**: "CRITICAL: Use variable NAME as key, not ID"
**Action Required**: NONE - ✅ ALREADY PERFECT (uses name-based key)

---

### 8. ElixirASTBuilder.hx:1056 ⚠️ NEEDS DUAL-KEY
**Location**: TVar expression (unused variable)
**Phase**: Builder
**Key Format**: ID-BASED - `Std.string(v.id)`
**Value**: `underscoreName` (with underscore prefix)
**Code Context**:
```haxe
Line 969: var idKey = Std.string(v.id);
Line 1055: var underscoreName = "_" + baseName;
Line 1056: currentContext.tempVarRenameMap.set(Std.string(v.id), underscoreName);
```
**Action Required**: Add name-based key alongside ID-based key

---

### 9. ElixirASTBuilder.hx:1061 ⚠️ NEEDS DUAL-KEY
**Location**: TVar expression (used variable)
**Phase**: Builder
**Key Format**: ID-BASED - `Std.string(v.id)`
**Value**: `baseName` (no underscore prefix)
**Code Context**:
```haxe
Line 1061: currentContext.tempVarRenameMap.set(Std.string(v.id), baseName);
```
**Comment**: "For used variables, also register to ensure consistency"
**Action Required**: Add name-based key alongside ID-based key

---

### 10. ElixirASTBuilder.hx:2292 ✅ INFRASTRUCTURE
**Location**: Function compilation (context copy)
**Phase**: Builder
**Key Format**: INHERITED (copies all from old context)
**Purpose**: Create new function scope preserving parent
**Code Context**:
```haxe
Line 2289: var oldTempVarRenameMap = currentContext.tempVarRenameMap;
Line 2290: currentContext.tempVarRenameMap = new Map();
Line 2291: for (key in oldTempVarRenameMap.keys()) {
Line 2292:     currentContext.tempVarRenameMap.set(key, oldTempVarRenameMap.get(key));
Line 2293: }
```
**Action Required**: NONE - preserves all keys

---

### 11. ElixirASTBuilder.hx:2363 ⚠️ NEEDS DUAL-KEY
**Location**: TFunction parameter processing
**Phase**: Builder
**Key Format**: ID-BASED - `idKey = Std.string(arg.v.id)`
**Value**: `finalName` (with underscore if unused)
**Code Context**:
```haxe
Line 2299: var idKey = Std.string(arg.v.id);
Line 2362: if (!currentContext.tempVarRenameMap.exists(idKey)) {
Line 2363:     currentContext.tempVarRenameMap.set(idKey, finalName);
Line 2364: }
```
**Action Required**: Add name-based key alongside ID-based key

---

## Summary Tables

### Files Analyzed
| File | Active Locations | Needs Modification |
|------|------------------|-------------------|
| ElixirCompiler.hx | 1 | 1 |
| CompilationContext.hx | 2 | 0 (infrastructure) |
| VariableBuilder.hx | 1 | 0 (✅ gold standard) |
| FunctionBuilder.hx | 2 | 1 |
| ElixirASTBuilder.hx | 5 | 3 |
| **TOTAL** | **11** | **5** |

### Locations Requiring Dual-Key Storage

| # | File:Line | Context | Variable Access |
|---|-----------|---------|----------------|
| 1 | ElixirCompiler.hx:1515 | Function param | arg.v.id + arg.v.name |
| 2 | FunctionBuilder.hx:190 | Function param | arg.v.id + arg.v.name |
| 3 | ElixirASTBuilder.hx:1056 | TVar unused | v.id + v.name |
| 4 | ElixirASTBuilder.hx:1061 | TVar used | v.id + v.name |
| 5 | ElixirASTBuilder.hx:2363 | TFunction param | arg.v.id + arg.v.name |

## Dual-Key Storage Pattern

### Implementation Template
```haxe
// BEFORE: Only ID-based key
var idKey = Std.string(v.id);
context.tempVarRenameMap.set(idKey, finalName);

// AFTER: Dual-key storage
var idKey = Std.string(v.id);
var varName = v.name;  // or baseName, depending on context

// Dual-key storage: ID for pattern positions, name for EVar references
context.tempVarRenameMap.set(idKey, finalName);     // ID-based (existing)
context.tempVarRenameMap.set(varName, finalName);   // NAME-based (NEW)

#if debug_hygiene
trace('[Hygiene] Dual-key registered: id=$idKey name=$varName -> $finalName');
#end
```

### Why This Works

1. **No Key Collisions**
   - Variable IDs are numeric strings: "57694"
   - Variable names are identifiers: "changeset"
   - These never overlap

2. **Supports Both Use Cases**
   - ID-based: Pattern matching transformations
   - Name-based: EVar reference renaming

3. **Backward Compatible**
   - Existing ID-based code continues to work
   - New name-based lookups now also work

## Root Cause of Original Bug

The bug occurred because:

1. **HygieneTransforms line 795** creates a fresh local Map
2. This loses ALL builder phase decisions
3. When transformer sees `EVar("changeset")`, it looks up by name
4. Name-based key doesn't exist (only ID-based keys were set)
5. Lookup fails → variable not renamed → "undefined variable" error

## Solution Architecture

### Two-Phase Fix

**Phase 1: Builder Dual-Key Storage** (Task 5)
- Modify 5 locations to set BOTH ID-based and name-based keys
- Ensures context contains complete information

**Phase 2: Transformer Context Initialization** (Tasks 2-4)
- Create `initializeNameMappingFromContext()` helper
- Extract name-based keys from context
- Modify line 795 to use context instead of empty map
- Preserves builder decisions in transformer phase

## Next Actions

1. ✅ **Task 1 COMPLETE** - All locations documented
2. ⏭️ **Task 2** - Implement `isNumericId` helper
3. ⏭️ **Task 3** - Implement `initializeNameMappingFromContext` helper
4. ⏭️ **Task 4** - Modify HygieneTransforms line 795
5. ⏭️ **Task 5** - Implement dual-key storage at 5 locations
6. ⏭️ **Task 6** - Create intended test output
7. ⏭️ **Task 7** - Comprehensive testing validation

## References

- **Original Issue**: undefined variable "changeset" in todo-app Users.changeset
- **Test Case**: test/snapshot/regression/simple_return_value/
- **Architecture**: Cumulative context pattern from Reflaxe.CSharp
- **SOLID Principle**: Builder detects → Context stores → Transformer applies
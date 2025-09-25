# JsonPrinter Loop Pattern Regression Test

## Purpose
This test reproduces and validates fixes for the JsonPrinter loop generation issues discovered by qa-sentinel.

## Issues Being Tested

### 1. Invalid Double Assignment Syntax
**Problem**: Generated code contained `i = g = g + 1` which is invalid Elixir syntax  
**Expected**: Clean lambda parameters without infrastructure variable assignments

### 2. Uninitialized Accumulator Variables
**Problem**: Variables like `items` and `result` were used without initialization  
**Expected**: Proper initialization or use of Enum.reduce with accumulator

### 3. Infrastructure Variable Leakage
**Problem**: Variables `g`, `g1`, `_g` from Haxe's desugaring leaked into output  
**Expected**: No infrastructure variables in generated code

### 4. Wrong Pattern Selection
**Problem**: Used `Enum.each` for accumulation (discards return values)  
**Expected**: Use `Enum.reduce` for accumulation, `Enum.each` only for side effects

## Test Structure

- `Main.hx`: Haxe input demonstrating the problematic loop patterns
- `intended/Main.ex`: Expected idiomatic Elixir output
- Key patterns tested:
  - Array iteration with string accumulation
  - Object field iteration with formatting
  - Proper use of Enum.reduce with index
  - No infrastructure variables in output

## Success Criteria

The compiler should generate Elixir code that:
1. Uses `Enum.reduce` for accumulation loops
2. Has no infrastructure variables (g, g1, _g)
3. Properly initializes accumulators
4. Generates valid Elixir syntax without double assignments
5. Matches the idiomatic patterns in `intended/Main.ex`
# Imperative → Functional Lowering (How Haxe Becomes Idiomatic Elixir)

Reflaxe.Elixir compiles Haxe (which allows mutation and loops) into Elixir (immutable, expression-oriented).
This page is a **high-level index + mental model** for how “imperative-looking” Haxe becomes **functional/immutable** Elixir, and where to be careful.

If you want the deep dive (with many examples), start here:

- `docs/07-patterns/FUNCTIONAL_PATTERNS.md` (core lowering patterns)
- `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md` (language mapping reference)
- `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md` (naming, unused vars, collision rules, hygiene)
- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md` (portable vs typed Elixir-first strategy)
- `docs/06-guides/KNOWN_LIMITATIONS.md` (sharp edges + experimental surfaces)

## The mental model

### 1) “Mutation” becomes **rebinding**

Elixir variables are immutable, but can be rebound in a new binding within scope.
Reflaxe.Elixir lowers Haxe mutation into **a sequence of rebindings** that preserves semantics.

Implication:
- The output is still purely functional/immutable at runtime, but reads like idiomatic Elixir rebinding.

### 2) “Loops” become **Enum/reduce recursion**

Haxe loops (`for`, `while`, `do/while`) are lowered into:
- `Enum.each` / `Enum.reduce` / `Enum.reduce_while` shapes when idiomatic and semantics-safe
- tail-recursive anonymous functions (when needed to preserve break/continue-like control flow)

Implication:
- Prefer writing Haxe code in “expression-first” style; the compiler has more room to emit clean `Enum.*` forms.

### 3) “Statements” become **expressions**

Elixir is expression-oriented; many things “return a value” naturally.
Haxe blocks are lowered into Elixir blocks and `case`/`cond`/`if` expressions (plus temporary bindings when needed).

Implication:
- Returning values from `if` / `switch` in Haxe typically maps cleanly to Elixir expressions.

## Common lowerings (by category)

### Variable updates

Typical transformations:
- `x += 1` → `x = x + 1`
- `x = f(x)` remains rebinding, not mutation
- `a.b = v` becomes a new struct/map value assigned back to `a` when targeting immutable BEAM data structures

See: `docs/07-patterns/FUNCTIONAL_PATTERNS.md`

### Data structure updates

Haxe “field assignment” and “map-like updates” lower into:
- struct updates (`%Mod{struct | field: value}`) when the target is a struct
- `Map.put` / functional update patterns when the target is a map-like structure

See: `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`

### Loops + break/continue semantics

Key idea:
- Haxe’s `break` / `continue` are not BEAM primitives, so the compiler must encode control flow.

When your Haxe loop is “pure iteration”, the compiler can emit `Enum.each`.
When you rely on early-exit semantics, it may emit `Enum.reduce_while` or a recursive encoding.

See: `docs/07-patterns/FUNCTIONAL_PATTERNS.md`

### Switch / pattern matching

Haxe `switch` often maps naturally to Elixir `case`.
The compiler may also optimize some patterns into more idiomatic match clauses when it is safe.

See: `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`

### Exceptions and error flow

Haxe exceptions map to Elixir `raise`/`try`/`rescue` patterns, but Elixir codebases often prefer:
- tagged return values (`{:ok, v}` / `{:error, reason}`)
- `with` / `case` flows

If you want “BEAM-first” error flow from Haxe, prefer `Result`/`Option`-style APIs.

See:
- `docs/07-patterns/FUNCTIONAL_PATTERNS.md`
- `docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md`

### Unused variables and hygiene

Elixir warnings around unused bindings are handled by:
- emitting `_name` bindings when a value is intentionally unused
- applying naming collision rules to avoid keywords and built-in collisions

See: `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md`

## Where to be careful (potential problems)

These are not necessarily “bugs” — they’re the places where the semantic gap between Haxe and Elixir is real, and the safest output can be less idiomatic.

### 1) Order of evaluation + side effects

Haxe code that mixes side effects inside complex expressions can constrain how idiomatic the Elixir lowering can be.
If you want the cleanest output, prefer:
- explicit intermediate bindings
- expression-first code (pure functions where possible)

### 2) Mutation-heavy code (ports from other targets)

Porting code that relies on pervasive mutation may still compile correctly, but:
- the generated Elixir may be rebinding-heavy
- performance characteristics may differ (more allocations from immutable updates)

Recommendation:
- treat “porting” as a starting point, then refactor toward BEAM-idiomatic patterns (see below).

### 3) “Reference identity” expectations

The BEAM does not have object identity/mutation semantics like JS/C++.
Code that relies on shared mutable references should be refactored to:
- explicit state passing
- processes (GenServer) for shared state

See: `docs/02-user-guide/PHOENIX_INTEGRATION.md` (OTP state patterns)

### 4) Escape hatches

Using `__elixir__()` / `Syntax.code()` can bypass compiler hygiene and typing guarantees.
Prefer adding a typed extern/abstraction in `std/elixir` / `std/phoenix` / `std/ecto` when reusable.

See:
- `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`
- `docs/06-guides/KNOWN_LIMITATIONS.md`

## Practical guidance: how to write “Elixir-first” Haxe

Start here:
- `docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md`
- `docs/07-patterns/quick-start-patterns.md`

Rules of thumb:
- Prefer `Result`/`Option` flows over exceptions for domain errors.
- Prefer data-in/data-out functions over mutation-heavy methods.
- Prefer small pure helpers; let Phoenix/OTP own long-lived state.
- Keep template/event names typed (opt-in strict modes) when building Phoenix apps.

## If something looks wrong

1) Check the mapping docs:
   - `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`
2) Check known limitations:
   - `docs/06-guides/KNOWN_LIMITATIONS.md`
3) If you suspect a codegen-shape regression, toggle the relevant feature flag to narrow scope:
   - `docs/04-api-reference/FEATURE_FLAGS.md`
4) Reduce to a minimal repro and add a snapshot test (or negative snapshot) when appropriate:
   - `docs/03-compiler-development/TESTING_INFRASTRUCTURE.md`

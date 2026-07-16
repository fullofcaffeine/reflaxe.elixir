# Imperative → Functional Lowering (How Haxe Becomes Idiomatic Elixir)

Reflaxe.Elixir compiles Haxe (which allows mutation and loops) into Elixir (immutable, expression-oriented).
This page is a **high-level index + mental model** for how “imperative-looking” Haxe becomes **functional/immutable** Elixir, and where to be careful.

If you want the deep dive (with many examples), start here:

- `docs/07-patterns/FUNCTIONAL_PATTERNS.md` (core lowering patterns)
- `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md` (language mapping reference)
- `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md` (naming, unused vars, collision rules, hygiene; includes variable binding vs rebinding details)
- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md` (portable vs typed Elixir-first strategy)
- `docs/06-guides/KNOWN_LIMITATIONS.md` (sharp edges + experimental surfaces)

## The mental model

### 1) Local value updates become **rebinding**

Elixir values are immutable, so a local scalar update or an explicitly native
value update can become a sequence of rebindings. Each step produces a new value
for that lexical binding while staying idiomatic in Elixir.

Example:

```haxe
var total = 1;
total += 2;
```

```elixir
total = 1
total = total + 2
```

Implication:

- The output is still purely functional/immutable at runtime, but reads like idiomatic Elixir rebinding.
- Generated code may rebind names to preserve Haxe mutation semantics; if you need "assign once" guarantees in source,
  use Haxe `final`.

Rebinding is **not** a general implementation of shared Haxe mutation. Consider:

```haxe
var values = [1];
var alias = values;
values.push(2);
trace(alias.length); // 2
```

```elixir
values = [1]
alias_values = values
values = values ++ [2]
length(alias_values) # 1, so this lowering is not equivalent
```

The current compiler does not yet preserve every alias-sensitive ordinary-Haxe
case. The accepted managed-reference design will use shared storage where the
Haxe contract requires it; it has not shipped yet. See
[Haxe Reference-Semantics Audit](../05-architecture/HAXE_REFERENCE_SEMANTICS_AUDIT.md).

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
- `a.b = v` becomes a new struct/map value assigned back to `a` only when `a`
  is an explicit native value (or a future optimization has proved the object
  local and unobservable). An ordinary shared Haxe object requires managed field
  mutation.

See: `docs/07-patterns/FUNCTIONAL_PATTERNS.md`

### Stateful receiver methods

Some current target APIs thread persistent receiver state explicitly:

```haxe
var iterator = new IntIterator(0, 2);
var first = iterator.next();
var stillHasItems = iterator.hasNext();
```

When such a method updates a persistent receiver and also returns a separate
value, the compiler can lower it to a same-scope rebind:

```elixir
iterator = IntIterator.new(0, 2)
{iterator, first} = IntIterator.next(iterator)
still_has_items = IntIterator.has_next(iterator)
```

This same-scope rebind matters for the variable being updated. The compiler must
not hide it inside an anonymous function/IIFE, because that would update only
the inner binding.

It still does not update another alias to the old receiver. The convention is
therefore complete only for explicitly persistent native APIs or for flows where
aliasing has been ruled out. Existing uses for ordinary mutable Haxe objects and
collections are compatibility machinery under audit, not proof of exact shared
reference behavior.

Current receiver conventions:

- Pure methods return only their Haxe value, for example `iterator.hasNext()`.
- Receiver mutators whose Haxe result is effectively `Void` return the updated receiver, for example `StringBuf.add(...)`
  and `haxe.io.BytesBuffer.add*`.
- Receiver mutators that also return a value return `{updated_receiver, value}`, for example `IntIterator.next()`.

### Data structure updates

Explicit native field and map-like updates lower into:

- struct updates (`%Mod{struct | field: value}`) when the target is a struct
- `Map.put` / functional update patterns when the target is a map-like structure

See: `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`

### Fresh one-to-one array projections

A common portable Haxe shape uses `push` to build one output value for every
input value:

```haxe
var lines = [];
for (message in history) {
	lines.push(MessageRules.format(message));
}
return lines;
```

When the compiler can prove that `lines` is a fresh empty array, the body has
exactly one ordered append per input, and no partial accumulator or receiver
state is involved, it emits the same structure an Elixir developer normally
writes:

```elixir
Enum.map(history, fn message -> MessageRules.format(message) end)
```

This proof is deliberately narrow. Conditional or multiple appends, reads such
as `lines.length`, non-empty accumulators, `break`/`continue`/non-local return,
explicit exception control flow, stateful iterators, and unproven instance
receiver calls stay on the general reducer path. Static projection calls are
safe here because `Enum.map` evaluates them once per input, in the same order,
and stops at the same thrown exception as `Enum.reduce`.

No feature flag is required. The former
`elixir.feature.idiomatic_comprehensions` define never controlled emission and
has been retired; semantics-proven output improvements belong to the single
normal compiler pipeline.

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

- emitting `_name` for unused function/callback parameters (readable signatures)
- using `_` for true throwaway pattern slots in generated `case`/`with`, while keeping `_name` when a named binder is needed to preserve pattern semantics
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

Porting code that relies on pervasive mutation may compile, but alias-sensitive
behavior is not fully supported yet:

- the generated Elixir may be rebinding-heavy
- performance characteristics may differ (more allocations from immutable updates)
- an alias to an ordinary class, array, map, list, or buffer can retain stale
  state under current persistent lowering

Recommendation:

- treat “porting” as a starting point, then refactor toward BEAM-idiomatic patterns (see below).

### 3) Reference identity and aliases

Ordinary immutable BEAM terms do not provide Haxe object identity or shared
field mutation. The issue is not isolated to `ObjectMap`: normal classes,
anonymous objects, arrays, Haxe maps, lists, and buffers may expose aliases.

For application state that is intentionally BEAM-native, prefer:

- explicit state passing; or
- processes such as a GenServer for long-lived shared state.

See: `docs/02-user-guide/PHOENIX_INTEGRATION.md` (OTP state patterns)

For ordinary portable Haxe compatibility, the compiler has accepted one typed,
selective managed-reference ABI for reference objects and audited mutable
collections. It is not implemented yet: ordinary alias behavior remains a
known gap, while `ObjectMap`, `ListSort`, `WeakMap`, and complete cyclic
reference graphs still fail fast or remain incomplete. Until the gates in
[Selective Managed-Reference ABI](../05-architecture/MANAGED_REFERENCE_ABI.md)
ship, the refactoring guidance above describes the supported application path.

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

# Strict Mode (Opt‑In)

Reflaxe.Elixir supports an **opt‑in strict mode** intended to give a Gleam‑like discipline when writing
Haxe for the BEAM: keep app code typed, structural, and free of escape hatches.

Strict mode is **not** enabled by default.

---

## Enable strict mode

Add this define to your server build `.hxml`:

```hxml
-D reflaxe_elixir_strict
```

Strict mode is enforced by `src/reflaxe/elixir/macros/StrictModeEnforcer.hx` during macro typing.

---

## What strict mode enforces

When enabled, the compiler **fails the build** if project-local sources contain:

1. **`untyped` expressions**
   - This includes `untyped __elixir__()` injections.
   - Rationale: `untyped` hides structure from the AST pipeline and makes transforms brittle.

2. **Explicit `Dynamic` types**
   - Use concrete types where possible.
   - Use `elixir.types.Term` only at BEAM boundaries (params/assigns/interop).

3. **Ad‑hoc `extern class` declarations**
   - Prefer moving reusable externs/wrappers into `std/` (framework-level).
   - For boundary externs that must live in app code, use a compiler-supported annotation such as `@:repo`.
   - If you must use an app-local extern anyway, you can explicitly acknowledge the escape hatch with:
     - `@:unsafeExtern`

Strict mode only scans **project-local sources** (under the current working directory) and excludes this
compiler’s own `src/reflaxe/**` and `std/**` code.

---

## What to do instead of escape hatches

Common replacements for `Dynamic` / `untyped`:

- Prefer typed Phoenix/Ecto wrappers in `std/phoenix` and `std/ecto` over ad-hoc injections.
- Keep boundary values typed as `elixir.types.Term` and decode to application types using small helpers
  (see `docs/07-patterns/FUNCTIONAL_PATTERNS.md`).

If strict mode blocks a real Phoenix/Ecto integration you need, that’s a signal the framework layer is
missing a reusable surface. Add it to `std/` (or a compiler-supported annotation module) so it benefits
all projects.


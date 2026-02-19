# Interop With Existing Pure Elixir Modules

This page exists for one common situation: part of your system is intentionally hand-written in Elixir, and Haxe code needs to call it.

Reflaxe.Elixir stays Haxe-first here:
- default path: typed `extern` surfaces
- optional layer: small Haxe wrappers for app ergonomics
- last resort: `untyped __elixir__()` when no typed surface is practical yet

## Runnable example in this repository

For a concrete end-to-end sample, see:

- `examples/13-elixir-first-liveview/src_elixir/elixir_first_liveview/legacy_slug.ex` (handwritten Elixir module)
- `examples/13-elixir-first-liveview/src_haxe/interop/LegacySlugExtern.hx` (typed extern boundary)
- `examples/13-elixir-first-liveview/src_haxe/interop/LegacySlugBridge.hx` (small app wrapper)
- `examples/13-elixir-first-liveview/src_haxe/live/InteropLive.hx` (normal Haxe call site)

Run `mix phx.server` in `examples/13-elixir-first-liveview` and open `/interop`.

## What "extern" and "__elixir__" mean

- `extern` in Haxe: a typed declaration for functions that already exist in Elixir. It does not emit a new Elixir module.
- `untyped __elixir__()`: a raw Elixir escape hatch. It is available, but it bypasses normal typed structure.

## 1) Default path: typed extern + optional wrapper

Why this section exists: most interop should be explicit and typed, so call sites stay readable and refactors stay safe.

### Haxe input

```haxe
package my_app.billing;

import elixir.ElixirResult;
import elixir.types.Term;
import haxe.functional.Result;

@:native("MyApp.LegacyBilling")
extern class LegacyBilling {
  @:native("charge")
  public static function charge(accountId: String, amountCents: Int): ElixirResult<String, Term>;
}

class BillingBridge {
  public static function charge(accountId: String, amountCents: Int): Result<String, Term> {
    return LegacyBilling.charge(accountId, amountCents).match(
      receiptId -> Result.Ok(receiptId),
      reason -> Result.Error(reason)
    );
  }
}
```

### Generated Elixir shape

```elixir
def charge(account_id, amount_cents) do
  case MyApp.LegacyBilling.charge(account_id, amount_cents) do
    {:ok, receipt_id} -> {:ok, receipt_id}
    {:error, reason} -> {:error, reason}
  end
end
```

### Why the compiler emits this

The `@:native("MyApp.LegacyBilling")` extern maps directly to your existing Elixir module call. The wrapper remains normal Haxe code, so the compiler can keep lowering it to regular Elixir `case`/tuple shapes.

## 2) When to add a wrapper

Why this section exists: wrappers are useful only when they remove repeated boundary work.

Add a wrapper when you need at least one of:
- repeated boundary decoding
- a stable app-level naming surface
- one place for `Result`/error conversion

Skip the wrapper when the extern call is already clear and used in only one place.

## 3) Last resort: `untyped __elixir__()` (available, discouraged)

Why this section exists: sometimes you need a feature before a typed extern exists, but this should stay intentional and local.

### Haxe input

```haxe
import elixir.types.Term;

class TimezoneBridge {
  // Temporary bridge while a typed wrapper is missing.
  public static function database(): Term {
    return untyped __elixir__("Calendar.get_time_zone_database()");
  }
}
```

### Generated Elixir shape

```elixir
def database do
  Calendar.get_time_zone_database()
end
```

### Why the compiler emits this

`__elixir__()` is injected as raw Elixir in the generated output. That is why it is powerful, but also why it should be used sparingly in app code.

For low-level rules and placeholder syntax, see `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`.

## 4) Strict mode behavior

Why this section exists: teams can opt into a no-escape-hatch policy.

With `-D reflaxe_elixir_strict`:
- app-local `untyped` (including `__elixir__()`) is rejected
- explicit `Dynamic` is rejected
- ad-hoc app-local externs are restricted

When you intentionally keep an app-local extern boundary, mark it explicitly (for example `@:unsafeExtern`) and keep it small and documented.

This same boundary pattern applies to typed OTP child specs when modules are hand-written in Elixir. See `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`.

If strict mode blocks a needed boundary, the preferred path is to add a typed surface in shared layers (`std/*`) or a documented, minimal project wrapper.

Reference: `docs/06-guides/STRICT_MODE.md`.

## 5) Decision checklist

Use this quick rule:

1. Existing Elixir module/function is stable and reusable: add a typed extern.
2. Many call sites or repeated decoding/error mapping: add a small wrapper.
3. Missing typed surface and immediate need: use `__elixir__()` locally, then replace with typed extern/wrapper.

Related docs:
- `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`
- `docs/02-user-guide/ESCAPE_HATCHES.md`
- `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`
- `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`

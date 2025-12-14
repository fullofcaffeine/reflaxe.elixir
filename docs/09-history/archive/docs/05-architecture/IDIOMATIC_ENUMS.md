# Idiomatic Enum Tags in Reflaxe.Elixir

Status: Adopted

## WHAT
- Reflaxe.Elixir can emit Haxe enums either as index‑tagged tuples (`{0}`, `{1, arg}`) or as atom‑tagged tuples (`{:ok, arg}`, `{:temporary}`).
- The `@:elixirIdiomatic` marker on a Haxe enum opts into atom‑tagged emission for that enum.

## DEFAULT (Without Marker)
- By default, enums are emitted using the constructor's integer index as the tag: `{idx, ...}` or `{idx}`.
- Rationale: this is target‑agnostic, mirrors Haxe's underlying enum representation, and avoids relying on constructor names when tags are unspecified.

## WHY USE `@:elixirIdiomatic`
- Elixir/OTP/Phoenix idioms expect atoms for many tag shapes:
  - Application start results: `{:ok, state} | {:error, reason} | :ignore`
  - Start types: `:normal | :temporary | :permanent`
  - Supervisor specs: `:worker | :supervisor`, restart/shutdown strategies, etc.
- Atom tags make matching readable and align generated code with hand‑written Elixir.

## WHEN TO USE IT
- Public surfaces that integrate with Elixir/OTP/Phoenix APIs and will be pattern‑matched on.
- Well‑known shapes where atom spellings are canonical and stable.
- Examples adopted in std:
  - `ApplicationResult`, `ApplicationStartType`
  - `Supervisor.RestartType`, `Supervisor.ShutdownType`, `Supervisor.ChildType`, `Supervisor.SupervisorStrategy`

## WHEN NOT TO USE IT
- Internal/cross‑target enums where index tags are sufficient, or where you deliberately want a stable index‑based ABI.
- Any case where atom spellings would be arbitrary or could drift across targets.

## HOW IT WORKS
- The compiler detects `@:elixirIdiomatic` and switches enum emission from integer indices to atoms for the tag position (see `ElixirCompiler.buildEnumAST`).
- Arguments are preserved. Example: `Ok(state)` → `{:ok, state}`; `Timeout(ms)` → `{:timeout, ms}`.

## EXAMPLES

### Haxe
```haxe
@:elixirIdiomatic
enum ApplicationResult {
  Ok(state: Dynamic);
  Error(reason: String);
  Ignore;
}
```

### Elixir Output
```elixir
defmodule Elixir.Otp.ApplicationResult do
  def ok(arg0),    do: {:ok, arg0}
  def error(arg0), do: {:error, arg0}
  def ignore(),    do: {:ignore}
end
```

## Policy Summary
- Do not blanket‑apply `@:elixirIdiomatic`. Use it where Elixir expects atoms; omit it elsewhere.
- This keeps generated code idiomatic without sacrificing cross‑target neutrality where atoms are not required.


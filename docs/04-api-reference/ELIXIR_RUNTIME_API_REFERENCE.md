# Elixir Runtime API Reference (User-Facing)

This page covers the Haxe typed extern surface that maps to core Elixir/Erlang
APIs. These modules are not a Haxe compatibility runtime; they are typed Haxe
names for ordinary Elixir modules and BEAM primitives.

## Core Module Families

### Language/Core

- `elixir.Kernel`
- `elixir.Atom`
- `elixir.Enum`
- `elixir.List`
- `elixir.Tuple`
- `elixir.ElixirMap`
- `elixir.ElixirString`
- `elixir.ElixirEnum`

Why use these surfaces:

- Keep generated output idiomatic and deterministic
- Preserve typing for common BEAM primitives in Haxe code
- Avoid stringly/dynamic interop at callsites

### Process/Concurrency/OTP

- Runtime-proven local subset: selected `elixir.Process`, `elixir.Task`, and `elixir.Agent` operations
- Application wiring: `elixir.Application`, `elixir.otp.Supervisor`, and `elixir.otp.TypeSafeChildSpec`
- Experimental surfaces: `elixir.GenServer`, `elixir.TaskSupervisor`, `elixir.Registry`, and custom
  `@:genserver` / `@:supervisor` callback generation

Use these typed names to emit standard Elixir runtime calls, but do not treat every declared extern as
a stable lifecycle promise. The exact supported operations, generated Elixir equivalents, evidence,
and exclusions are in the [OTP Support Contract](OTP_SUPPORT_CONTRACT.md).

`TypeSafeChildSpec` guidance:

- Prefer typed module refs (`TypeSafeChildSpec.endpoint(EndpointExtern)`) so unresolved modules fail at compile time.
- For pure Elixir modules, add a small `@:native("...") extern class ... {}` wrapper and keep callsites typed (add `@:unsafeExtern` where strict mode requires explicit app-local boundaries).
- Use `*Unsafe` variants only for intentional dynamic/legacy strings.
- Canonical API reference: `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`.
- The covered 1.0 behavior is composition and documented application boot; arbitrary restart/failure
  policy remains outside the stable OTP subset.

### IO/System/Utility

- `elixir.IO`, `elixir.File`, `elixir.Path`, `elixir.System`, `elixir.Regex`, `elixir.Stream`, `elixir.DateTime`
- `elixir.Module`, `elixir.Code`, `elixir.Node`, `elixir.Registry`
- `elixir.HttpClient`, `elixir.Jason`

Use `elixir.System.SystemTimeUnit` for VM clock operations and
`elixir.DateTime.TimeUnit` for calendar/date-time operations. They are distinct
typed surfaces because Elixir accepts different unit sets at those boundaries;
both still generate ordinary atoms such as `:millisecond`.

## Typed Wrapper Modules (`elixir.types.*`)

Typed wrappers are provided for BEAM values and runtime contracts:

- core values: `Term`, `Atom`, `Pid`, `Reference`
- process/runtime info: `ProcessInfo`, `ProcessFlag`, `MessageQueueData`, `ExitReason`
- GenServer contracts: `GenServerRef`, `GenServerOption`, `GenServerCallbackResults`
- task/registry: `TaskRef`, `TaskResult`, `RegistryKey`, `RegistryOptions`

Why wrappers matter:

- improve compile-time safety at boundary-heavy code
- reduce accidental `Dynamic` spread in business logic
- clarify runtime semantics in signatures

Use these wrappers at interop boundaries, not as an excuse to route ordinary
stdlib behavior through a generic runtime layer. When a Haxe stdlib API has a
natural BEAM implementation, the target stdlib should call that implementation
directly or let the compiler lower to idiomatic Elixir.

## Naming and Interop Metadata

Most runtime interop modules use metadata such as:

- `@:native` to pin exact target module/function names
- `@:overload` to expose ergonomic type-safe signatures over one emitted runtime implementation
- `@:from` / `@:to` for typed conversion abstractions

## Common Usage Patterns

- Prefer typed wrappers (`Term`, typed result enums, typed callback result unions) over raw dynamic maps
- Keep OTP callback signatures explicit and consistent with target callback contracts
- Use child-spec helpers for supervision tree composition instead of ad-hoc tuple/string assembly

## Common Failure Modes

- Missing `@:native` on callback/function names that must map to exact Elixir callback names
- Treating wrappers as runtime allocations rather than compile-time type surfaces
- Overusing raw `Term` in code that can be strongly typed via provided wrappers

## Related Docs

- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/04-api-reference/HAXE_MACRO_APIS.md`
- `docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md`
- `docs/04-api-reference/OTP_SUPPORT_CONTRACT.md`
- `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`

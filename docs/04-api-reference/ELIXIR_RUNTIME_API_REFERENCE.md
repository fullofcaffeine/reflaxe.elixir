# Elixir Runtime API Reference (User-Facing)

This page covers the Haxe extern/runtime surface that maps to core Elixir/Erlang APIs.

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

- `elixir.Process`
- `elixir.GenServer`
- `elixir.Task`
- `elixir.TaskSupervisor`
- `elixir.Application`
- `elixir.otp.Supervisor`
- `elixir.otp.TypeSafeChildSpec`

Use these for typed OTP process and supervision-tree composition in Haxe while emitting standard Elixir runtime patterns.

`TypeSafeChildSpec` guidance:

- Prefer typed module refs (`TypeSafeChildSpec.endpoint(EndpointExtern)`) so unresolved modules fail at compile time.
- For pure Elixir modules, add a small `@:native("...") extern class ... {}` wrapper and keep callsites typed (add `@:unsafeExtern` where strict mode requires explicit app-local boundaries).
- Use `*Unsafe` variants only for intentional dynamic/legacy strings.
- Canonical API reference: `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`.

### IO/System/Utility

- `elixir.IO`, `elixir.File`, `elixir.Path`, `elixir.System`, `elixir.Regex`, `elixir.Stream`, `elixir.DateTime`
- `elixir.Module`, `elixir.Code`, `elixir.Node`, `elixir.Registry`
- `elixir.HttpClient`, `elixir.Jason`

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
- `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`

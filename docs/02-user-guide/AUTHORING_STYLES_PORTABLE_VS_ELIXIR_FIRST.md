# Authoring Profiles: Portable vs Elixir-First

Reflaxe.Elixir supports two valid application authoring profiles for the BEAM:

1. **Portable stdlib-first**
2. **Typed Elixir-first**

Both are supported **today**.

## One pipeline, two profiles

Reflaxe.Elixir has one semantics-preserving compilation pipeline (TypedExpr -> ElixirAST -> passes -> printer).

These are **authoring profiles**, not separate backends.

- You do not switch to a separate “portable mode compiler”.
- You do not switch to a separate “metal mode compiler”.
- You choose how much of your app surface is portability-oriented vs BEAM-native extern-oriented.

See also: `docs/04-api-reference/FEATURE_FLAGS.md`.

## Idiomatic output contract

Both profiles should generate as much idiomatic Elixir as possible.

The difference is what wins when Haxe portability and BEAM-native shape conflict:

- **Portable stdlib-first**: preserve Haxe semantics and cross-target reuse first; emit idiomatic Elixir where that is safe.
- **Typed Elixir-first**: prefer BEAM/Phoenix/Ecto/OTP-native source shapes first; this gives the compiler more room to emit code that looks like handwritten Elixir.

Portable is not an “unidiomatic” profile. It still prefers Elixir modules, functions, maps, tuples, pattern matching, `case`, `Enum`, and normal Phoenix `~H` output where those shapes preserve Haxe behavior.

When semantics differ, portable code may need Haxe-compatible lowering or helper modules for things like Haxe stdlib APIs, class semantics, mutable-looking loops, iterators, exceptions, nullable behavior, and map behavior.

## Why there is no application-wide `metal` profile

For Reflaxe.Elixir, `metal` is reserved for local target-syntax escape hatches, especially HXX/HEEx template authoring (`@:hxx_mode("metal")`). It is not a project-wide compiler identity.

Use this mental model:

- **Authoring profile**: `portable` or `elixir-first`
- **Strictness guardrail**: `-D reflaxe_elixir_strict` and HXX strict flags
- **Escape hatch**: `@:allow_heex`, `@:hxx_mode("metal")`, or low-level Elixir injection in compiler/stdlib internals

This keeps the public model focused on what users are trying to build, while keeping raw target syntax explicit and local.

## Compiler defines and warnings

There is currently no `portable` or `elixir-first` compiler backend switch.

That is intentional. The current compiler approach is:

- one semantics-preserving pipeline
- source shapes and imports communicate intent
- strictness flags enforce safety where needed
- local escape hatches stay explicit

This is enough for the compiler today because most projects mix profiles by layer. A project-wide define would be too blunt for apps that have portable domain modules and Elixir-first Phoenix/Ecto edges in the same build.

If Reflaxe.Elixir adds profile defines later, they should be advisory guardrails, not codegen modes. For example, a future profile setting could help emit warnings when code clearly violates the declared intent:

- In a declared portable module, warn on direct `phoenix.*`, `ecto.*`, `elixir.*`, or raw target-syntax usage outside explicit boundary modules.
- In a declared Elixir-first module, warn on patterns that are likely to produce bulky Haxe-compatibility lowering when a BEAM-native extern or typed boundary would be clearer.
- In either profile, keep using the same compiler pipeline and preserve semantics.

Strictness remains orthogonal:

- `-D reflaxe_elixir_strict` rejects broad escape hatches such as `Dynamic`, `untyped`, and ad-hoc app externs.
- HXX strict flags (`hxx_strict_*`) validate templates more aggressively.
- `@:hxx_mode("metal")` and `@:allow_heex` remain local escape hatches.

Because most real apps mix profiles by layer, module-level intent is usually more useful than a project-wide profile define.

## Current approach vs profile defines

| Approach | How it works | Benefits | Costs / risks | Recommendation |
| --- | --- | --- | --- | --- |
| Current approach | Use normal Haxe code shape, imports, typed externs, strict flags, and local metadata. | No extra config; works naturally for mixed apps; no risk of users thinking profiles are separate backends. | Less room for intent-specific warnings until dedicated linting exists. | Keep this as the default compiler model. |
| Project-wide profile define | Example: `-D reflaxe_elixir_profile=portable` or `-D reflaxe_elixir_profile=elixir_first`. | Explicit build-level declaration; could drive broad warnings. | Too coarse for real apps; likely noisy; encourages false “one app, one profile” thinking; easy to mistake for codegen mode. | Avoid unless a real linting need appears. |
| Module-level profile metadata | Example future idea: `@:elixir_profile("portable")` on a package boundary/module. | More precise than a project-wide define; useful for warnings at boundaries. | More metadata to maintain; still should not change semantics. | Consider later only as an advisory lint feature. |

If a profile declaration is added later, it should answer “what warnings should I get?” not “which compiler backend should run?”.

## Examples

### Portable domain module

This code is portable because it uses Haxe stdlib/domain types and no BEAM-specific APIs:

```haxe
package shared;

typedef Message = {
  text:String,
  author:String
};

class MessageRules {
  public static function isValid(message:Message):Bool {
    return StringTools.trim(message.text) != "" && StringTools.trim(message.author) != "";
  }

  public static function normalize(message:Message):Message {
    return {
      text: StringTools.trim(message.text),
      author: StringTools.trim(message.author)
    };
  }
}
```

Expected Elixir tendency:

- Use normal functions and maps/struct-like values.
- Use native string/list/map operations where they preserve Haxe behavior.
- Add Haxe-compatible lowering only where the stdlib contract requires it.

No profile define is needed. The code itself communicates portability.

### Elixir-first Phoenix edge

This code is Elixir-first because it models Phoenix callback shapes directly:

```haxe
package web;

import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.Socket;
import shared.MessageRules;

typedef ChatAssigns = {
  draft:String
};

@:native("MyAppWeb.ChatLive")
@:liveview
class ChatLive {
  @:native("handle_event")
  public static function handleEvent(event:String, params:Term, socket:Socket<ChatAssigns>):HandleEventResult<ChatAssigns> {
    return switch (event) {
      case "validate":
        var message = { text: socket.assigns.draft, author: "me" };
        var valid = MessageRules.isValid(message);
        NoReply(socket.assign(_.draft, valid ? message.text : ""));
      case _:
        NoReply(socket);
    }
  }
}
```

Expected Elixir tendency:

- Emit Phoenix callback functions and tagged return tuples.
- Keep `Socket<TAssigns>`/assign updates close to Phoenix conventions.
- Call portable domain helpers at the boundary without forcing the whole app to become portable.

Again, no profile define is needed. The imports and callback types communicate that this module is Elixir-first.

### Mixed project layout

Recommended layout for many apps:

```text
src_haxe/
  shared/          # portable stdlib-first domain logic
  web/             # Elixir-first Phoenix/LiveView modules
  persistence/     # Elixir-first Ecto/Repo modules
  interop/         # typed extern boundaries to existing Elixir
```

The whole build still uses one HXML and one compiler pipeline:

```hxml
-lib reflaxe.elixir
-cp src_haxe
-main web.App

-D reflaxe_runtime
-D elixir_output=lib/my_app_hx
-D app_name=MyApp

# Optional safety guardrails, not authoring-profile switches:
-D reflaxe_elixir_strict
-D hxx_strict_components
-D hxx_strict_slots
-D hxx_strict_phx_events
```

This keeps the profile decision close to the code instead of putting it in a global build flag.

## Profile A: Portable stdlib-first

Use this when you want maximum cross-target reuse.

Typical characteristics:

- Domain logic uses Haxe stdlib types/APIs.
- Target-specific integrations stay at small boundaries.
- You can often reuse the same domain modules on JS/other targets.
- The compiler still emits idiomatic Elixir where it can do so without changing Haxe behavior.

Start here:

- `docs/02-user-guide/PORTING_STDLIB_CODE_JS_TO_ELIXIR.md`
- `docs/06-guides/PORTABLE_CHAT_TUTORIAL.md`
- `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`

## Profile B: Typed Elixir-first

Use this when your app is primarily Phoenix/Ecto/OTP and you want BEAM-native shapes in your Haxe source.

Typical characteristics:

- Prefer `phoenix.*`, `ecto.*`, and `elixir.*` extern surfaces.
- Decode `Term` at boundaries early.
- Keep success/error flow explicit with `haxe.functional.Result`.
- Minimize portability constraints in integration-heavy modules.
- Generated code can be more naturally Elixir-shaped because the source already models Elixir concepts.

Start here:

- `examples/13-elixir-first-liveview/README.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `docs/06-guides/STRICT_MODE.md`
- `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`

## Strictness guardrails

### `-D reflaxe_elixir_strict` (user-facing)

Use this in real projects for Gleam-like guardrails in app code. It rejects:

- `untyped` (including `untyped __elixir__()`)
- explicit `Dynamic`
- ad-hoc app extern classes (except allowed boundary annotations)

### `-D reflaxe_elixir_strict_examples` (repo policy)

This is a repository policy guard for shipped examples.
It keeps examples Haxe-first by rejecting escape-hatch usage in `examples/*/src_haxe/**`.

If you are building an app, prefer `reflaxe_elixir_strict`.

## “Almost no stdlib” Elixir-first rules

When intentionally writing typed Elixir-first code:

- Prefer Elixir/Phoenix/Ecto extern APIs at integration boundaries.
- Keep `Term` boundaries explicit and decode immediately.
- Use `Result`/`Option` for explicit error/absence handling.
- Avoid app-level `untyped __elixir__()` and `Dynamic`.
- Keep portability-first abstractions for pure domain modules only when they add clear value.

## Performance: what to claim safely

It is reasonable to expect that Elixir-first authoring can reduce some lowering complexity for specific code paths.

Do not claim blanket speedups without measurement.

Use:

```bash
haxe build.hxml --times
haxe build.hxml -D macro-times --times
```

For repo-level guidance:

- `docs/06-guides/PERFORMANCE_GUIDE.md`

## Choosing a profile per module (recommended)

Most production apps benefit from mixing profiles by layer:

- **Domain core**: portable stdlib-first when reuse matters.
- **Phoenix/Ecto/OTP edges**: typed Elixir-first.

This keeps reuse where it pays off, while keeping framework-heavy code idiomatic and explicit.

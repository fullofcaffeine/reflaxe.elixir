# Handwritten-Output Quality Corpus

This corpus answers a stricter question than "does the generated Elixir
compile?": does representative output still look like code an Elixir team can
review, and are the non-native shapes present for an understood reason?

Each fixture keeps three artifacts connected in `manifest.json`:

1. the real Haxe source in `examples/`;
2. an exact, Mix-formatted generated snapshot under `generated/`;
3. a small handwritten Elixir comparison under `handwritten/`.

The handwritten files are review aids, not alternate implementations and not
semantic golden files. Haxe and Elixir differ in mutation, class dispatch,
numeric edge cases, and stdlib behavior. When preserving Haxe semantics needs a
helper or a less-native shape, the manifest records why and links the bead that
owns the possible improvement.

## What CI Checks

`npm run test:handwritten-output` rebuilds all fixtures into a temporary
directory and then checks four independent layers:

- **Syntax and presentation:** every generated file is canonical under the
  project's Mix formatter.
- **Reviewed structure:** selected files match the checked-in generated
  snapshots exactly.
- **Semantic compatibility artifacts:** `_ =` matches, expression IIFEs,
  `StringTools`/Reflaxe helper calls, and reducer appends must have an exact
  file-scoped allowance with a reason and tracking bead.
- **Support footprint:** every generated non-application module belongs to one
  justified support group, and neither the group nor total footprint may grow
  silently.

Warnings-as-errors and runtime semantics stay in their normal test layers. The
corpus examples run through Haxe-authored ExUnit tests, the examples WAE jobs,
and the todo-app sentinel rather than duplicating those systems here.

## Reviewed Slices

| Lane | Haxe source | Generated snapshot | Handwritten comparison | Main review question |
| --- | --- | --- | --- | --- |
| Elixir-first domain | [SearchDomain.hx](../../../examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx) | [search_domain.ex](generated/elixir-first-liveview/elixir_first_liveview/search_domain.ex) | [search_domain.ex](handwritten/elixir-first-liveview/search_domain.ex) | Are Result, Enum, and String operations ordinary Elixir? |
| Phoenix LiveView | [SearchLive.hx](../../../examples/13-elixir-first-liveview/src_haxe/live/SearchLive.hx) | [search_live.ex](generated/elixir-first-liveview/elixir_first_liveview_web/search_live.ex) | [search_live.ex](handwritten/elixir-first-liveview/search_live.ex) | Are callbacks, assigns, and HEEx Phoenix-native? |
| Typed abstraction | [ImmediateRetryPolicy.hx](../../../examples/14-abstraction-lab/src_haxe/implementations/ImmediateRetryPolicy.hx) | [immediate_retry_policy.ex](generated/abstraction-lab/abstraction_lab/immediate_retry_policy.ex) | [immediate_retry_policy.ex](handwritten/abstraction-lab/immediate_retry_policy.ex) | What class-dispatch cost does the Haxe abstraction retain? |
| OTP boundary | [ProcessBoundary.hx](../../../examples/14-abstraction-lab/src_haxe/abstractions/ProcessBoundary.hx) | [process_boundary.ex](generated/abstraction-lab/abstraction_lab/process_boundary.ex) | [process_boundary.ex](handwritten/abstraction-lab/process_boundary.ex) | Do typed boundaries become direct Kernel calls? |
| Portable domain | [MessageRules.hx](../../../examples/16-portable-chat-domain/src_haxe/shared/chat/MessageRules.hx) | [message_rules.ex](generated/portable-chat-domain/portable_chat_domain/message_rules.ex) | [message_rules.ex](handwritten/portable-chat-domain/message_rules.ex) | Which StringTools/IIFE shapes are compatibility costs? |
| Imperative collection | [Transcript.hx](../../../examples/16-portable-chat-domain/src_haxe/shared/chat/Transcript.hx) | [transcript.ex](generated/portable-chat-domain/portable_chat_domain/transcript.ex) | [transcript.ex](handwritten/portable-chat-domain/transcript.ex) | Does a proven fresh one-to-one append loop become direct `Enum.map`? |
| Target adapter | [PortableChatServer.hx](../../../examples/16-portable-chat-domain/src_haxe/server/PortableChatServer.hx) | [portable_chat_server.ex](generated/portable-chat-domain/portable_chat_domain/portable_chat_server.ex) | [portable_chat_server.ex](handwritten/portable-chat-domain/portable_chat_server.ex) | Does target-specific glue stay small and native? |
| Ecto schema | [Todo.hx](../../../examples/todo-app/src_haxe/server/schemas/Todo.hx) | [todo.ex](generated/todo-phoenix/todo_app/todo.ex) | [todo.ex](handwritten/todo-phoenix/todo.ex) | Are schema and changeset APIs native despite Haxe class construction? |

The exact paths and the expected differences live in `manifest.json`, which is
the machine-checked source of truth.

## Updating Deliberately

After an intentional compiler change:

```bash
npm run update:handwritten-output
npm run test:handwritten-output
```

Review the generated diff beside the Haxe source and handwritten comparison.
Do not update a snapshot to hide a regression. If a metric changes, edit its
manifest allowance separately and explain why. New application-visible helper
calls should normally be fixed in the compiler; they should not receive a
generic repository-wide exception.

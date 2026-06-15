# Portable Chat Tutorial (Shared Haxe Domain)

This tutorial shows the portable-authoring lane: write a small chat domain once in Haxe, keep it target-agnostic, and compile it to both Elixir and JavaScript.

Use this when portability is the main goal. If you want a Phoenix-first tutorial with LiveView, PubSub, and Presence wiring, use:

- `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`
- `docs/06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md`

## The Shape

The runnable example is `examples/16-portable-chat-domain/`.

It has three layers:

- `src_haxe/shared/chat/**` - portable domain code only.
- `src_haxe/server/**` - thin Elixir-target adapter/demo.
- `src_haxe/client/**` - thin JavaScript-target adapter/demo.

The portable layer must not import `elixir.*`, `phoenix.*`, or `js.*`. Those imports belong at the edge.

## Build Both Targets

```bash
cd examples/16-portable-chat-domain
haxe build.hxml
```

`build.hxml` delegates to:

- `build-elixir.hxml`, which emits Elixir under `lib/`
- `build-js.hxml`, which emits JavaScript under `dist/`

You can run the JS proof directly:

```bash
node dist/portable_chat_domain.js
```

And you can validate the generated Elixir with warnings as errors:

```bash
elixirc --warnings-as-errors -o _build/elixirc_validate $(find lib -type f -name "*.ex" | sort)
```

## Portable Domain Code

The core domain is plain Haxe:

```haxe
package shared.chat;

typedef ChatMessage = {
	var author:String;
	var body:String;
	var preview:String;
}

enum MessageDecision {
	Accepted(message:ChatMessage);
	Rejected(reason:String);
}

class MessageRules {
	public static function validate(author:String, body:String):MessageDecision {
		var normalizedAuthor = normalizeAuthor(author);
		var normalizedBody = normalizeBody(body);

		if (normalizedAuthor.length == 0) {
			return Rejected("author is required");
		}

		if (normalizedBody.length == 0) {
			return Rejected("message body is required");
		}

		return Accepted({
			author: normalizedAuthor,
			body: normalizedBody,
			preview: preview(normalizedBody)
		});
	}
}
```

The important part is not the validation itself. The important part is what is absent:

- No `Term`.
- No `Atom`.
- No Phoenix socket, PubSub, Presence, or LiveView APIs.
- No browser APIs.

That keeps the domain reusable across targets.

## Elixir Adapter

`src_haxe/server/PortableChatServer.hx` proves that the shared domain compiles to Elixir:

```haxe
package server;

import shared.chat.Transcript;

class PortableChatServer {
	public static function sampleSummary():String {
		var history = Transcript.empty();
		history = Transcript.add(history, "Ada", " Hello from the BEAM side. ");
		return Transcript.render(history).join(" | ");
	}
}
```

In a real Phoenix app, this adapter is where you would decode event params, call the portable domain, and then assign or broadcast through typed Phoenix externs.

## JavaScript Adapter

`src_haxe/client/PortableChatClient.hx` proves that the same domain compiles to JS:

```haxe
package client;

import shared.chat.Transcript;

class PortableChatClient {
	public static function main():Void {
		var history = Transcript.empty();
		history = Transcript.add(history, "Grace", "The same Haxe rules compiled to JS.");

		for (line in Transcript.render(history)) {
			trace(line);
		}
	}
}
```

In a Phoenix app, the JS adapter could power client-side validation or render hints while the Elixir adapter remains authoritative on the server.

## How This Differs From Phoenix-First Chat

Portable chat:

- optimizes for shared domain reuse
- keeps framework APIs out of core logic
- uses target-specific adapters only at the boundary

Phoenix-first chat:

- optimizes for idiomatic Phoenix integration
- uses typed LiveView/PubSub/Presence externs directly in app modules
- still can call portable helpers, but portability is not the primary teaching goal

Both approaches generate idiomatic Elixir where they target Elixir. The difference is source organization and coupling, not a separate compiler backend.

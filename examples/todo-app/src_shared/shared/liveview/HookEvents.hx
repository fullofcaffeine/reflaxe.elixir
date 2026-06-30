package shared.liveview;

import phoenix.live_view.LiveEventProtocolCompanion;

/**
 * Shared LiveView hook events for the todo app.
 *
 * WHAT
 * - Declares client-pushed hook event names and payload shapes once for both
 *   frontend Haxe compiled to JS with Genes and backend Haxe compiled to
 *   Phoenix LiveView.
 *
 * WHY
 * - LiveView hooks are a front/back boundary. The generated `HookEvents`
 *   companion keeps hook pushes and server dispatchers in sync without
 *   handwritten payload codecs.
 */
@:liveEventProtocol
enum HookClientEvent {
	@:hookEvent
	ClipboardCopied(message:String);

	@:hookEvent("ping")
	HookPing;
}

typedef HookEvents = LiveEventProtocolCompanion<HookClientEvent>;

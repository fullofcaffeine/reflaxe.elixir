package shared.liveview;

import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
import phoenix.channels.WirePayload;

/**
 * Shared LiveView hook events for the todo app.
 *
 * WHAT
 * - Defines client-pushed hook event names and payload shapes once for both:
 *   - frontend Haxe compiled to JS with Genes
 *   - backend Haxe compiled to Phoenix LiveView
 *
 * WHY
 * - LiveView hooks are a front/back boundary. Keeping event names and payload
 *   codecs in shared Haxe gives us compiler-checked drift detection instead of
 *   stringly JS plus hand-decoded server params.
 */
typedef ClipboardCopiedPayload = {
	var message:String;
}

enum HookClientEvent {
	ClipboardCopied(payload:ClipboardCopiedPayload);
	HookPing;
}

class HookEvents {
	public static inline var WireKeyMessage:String = "message";
	public static inline var DefaultClipboardCopiedMessage:String = "Copied.";

	public static function clipboardCopied(message:String):HookClientEvent {
		return ClipboardCopied({message: message == "" ? DefaultClipboardCopiedMessage : message});
	}

	public static function encodeClientPush(event:HookClientEvent):EncodedEvent {
		return switch (event) {
			case ClipboardCopied(payload):
				{event: EventName.ClipboardCopied, payload: encodeClipboardCopiedPayload(payload)};
			case HookPing:
				{event: EventName.HookPing, payload: WirePayload.empty()};
		};
	}

	public static function decodeServerRecv(eventName:String, payload:Payload):Null<HookClientEvent> {
		if (eventName == EventName.ClipboardCopied) {
			var decoded = decodeClipboardCopiedPayload(payload);
			return decoded != null ? ClipboardCopied(decoded) : null;
		}
		if (eventName == EventName.HookPing) {
			return HookPing;
		}
		return null;
	}

	static function encodeClipboardCopiedPayload(payload:ClipboardCopiedPayload):Payload {
		var wire = WirePayload.empty();
		return WirePayload.putString(wire, WireKeyMessage, payload.message);
	}

	static function decodeClipboardCopiedPayload(payload:Payload):Null<ClipboardCopiedPayload> {
		var message = WirePayload.getString(payload, WireKeyMessage);
		return message != null ? {message: message} : null;
	}
}

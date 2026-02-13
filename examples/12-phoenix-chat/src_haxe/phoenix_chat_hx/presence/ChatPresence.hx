package phoenix_chat_hx.presence;

import phoenix.PresenceBehavior;

/**
 * Presence module for the Phoenix chat example.
 *
 * WHAT
 * - Declares `PhoenixChatWeb.Presence` as a Phoenix.Presence module via the @:presence transform.
 *
 * WHY
 * - The chat app uses Presence state to drive the "Online" list and count.
 *
 * HOW
 * - @:native sets the generated module name.
 * - @:presence injects `use Phoenix.Presence, otp_app: ...` at the Elixir level.
 */
typedef PresenceMeta = {
	var onlineAt:Float;
	var name:String;
}

// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.

@:native("PhoenixChatWeb.Presence")
// @:presence: emits a Phoenix.Presence module for realtime presence tracking.
@:presence
class ChatPresence implements PresenceBehavior {}

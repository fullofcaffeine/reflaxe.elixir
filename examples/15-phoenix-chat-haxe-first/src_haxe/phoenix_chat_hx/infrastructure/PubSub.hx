package phoenix_chat_hx.infrastructure;

/**
 * Typed wrapper for the app PubSub module.
 */
@:native("PhoenixChat.PubSub")
@:unsafeExtern // Intentional app-level extern boundary for pure Elixir module interop.
extern class PubSub {}

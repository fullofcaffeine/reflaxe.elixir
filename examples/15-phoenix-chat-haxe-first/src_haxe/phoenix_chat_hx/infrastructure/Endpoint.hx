package phoenix_chat_hx.infrastructure;

/**
 * Typed wrapper for the Phoenix endpoint module.
 */
@:native("PhoenixChatWeb.Endpoint")
@:unsafeExtern // Intentional app-level extern boundary for pure Elixir module interop.
extern class Endpoint {}

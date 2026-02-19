package phoenix_chat_hx.infrastructure;

/**
 * Typed wrapper for the telemetry module.
 */
@:native("PhoenixChatWeb.Telemetry")
@:unsafeExtern // Intentional app-level extern boundary for pure Elixir module interop.
extern class Telemetry {}

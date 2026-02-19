package server.infrastructure;

/**
 * Typed wrapper for the app PubSub module.
 */
@:native("PhoenixHaxeExample.PubSub")
@:unsafeExtern // Intentional app-level extern boundary for pure Elixir module interop.
extern class PubSub {}

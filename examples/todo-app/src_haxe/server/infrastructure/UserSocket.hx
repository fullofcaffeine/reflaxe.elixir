package server.infrastructure;

/**
 * UserSocket
 *
 * WHAT
 * - Phoenix socket module for Channels (mounted at `/socket` by the endpoint).
 *
 * WHY
 * - Channels require a socket module to declare topic routes:
 *   `channel "topic:*", SomeChannel`.
 * - Haxe class bodies cannot contain Elixir module-level directives, so we
 *   generate them from annotations.
 *
 * HOW
 * - `@:socket` marks this as a Phoenix.Socket module.
 * - `@:socketChannels` declares channel routes.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoAppWeb.UserSocket")
// @:socket: marks this module as a Phoenix.Socket definition for channel routing.
@:socket
// @:socketChannels: declares topic-to-channel mappings for a `@:socket` module.
@:socketChannels([{topic: "typed:*", channel: server.channels.PingChannel}])
class UserSocket {}

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
@:native("TodoAppWeb.UserSocket")
@:socket
@:socketChannels([
    {topic: "typed:*", channel: server.channels.PingChannel}
])
class UserSocket {}


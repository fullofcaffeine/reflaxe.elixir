package phoenix;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Phoenix.Channel (server-side)
 *
 * WHAT
 * - Minimal externs for server-side `Phoenix.Channel`.
 *
 * WHY
 * - Channel callbacks frequently broadcast or push messages.
 * - We keep this surface minimal and faithful to Phoenix.
 *
 * HOW
 * - Map functions 1:1 to `Phoenix.Channel.*`.
 * - Keep payloads as `Term` to avoid over-constraining JSON/map shapes.
 */
@:native("Phoenix.Channel")
extern class Channel {
  static function broadcast(socket: Term, event: String, payload: Term): Term;
  @:native("broadcast!") static function broadcastBang(socket: Term, event: String, payload: Term): Term;

  @:native("broadcast_from")
  static function broadcastFrom(socket: Term, event: String, payload: Term): Term;

  @:native("broadcast_from!")
  static function broadcastFromBang(socket: Term, event: String, payload: Term): Term;

  static function push(socket: Term, event: String, payload: Term): Term;

  /**
   * Replies asynchronously to a socket push.
   *
   * NOTE: Phoenix allows `reply(socket_ref, :ok)` and `reply(socket_ref, {:ok, payload})`.
   * We keep the type as `Term` so callers can pass either shape.
   */
  static function reply(socketRef: Term, status: Term): Term;

  @:native("socket_ref")
  static function socketRef(socket: Term): Term;
}

#end

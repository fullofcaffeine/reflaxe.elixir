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
}

#end


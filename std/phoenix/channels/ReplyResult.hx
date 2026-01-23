package phoenix.channels;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * ReplyResult (Phoenix Channels)
 *
 * WHAT
 * - Typed return values for Phoenix Channel callbacks like `handle_in/3`, `handle_info/2`,
 *   and `handle_out/3`.
 *
 * WHY
 * - Channel callbacks must return specific tuple shapes (e.g. `{:noreply, socket}`) and it's
 *   easy to get the atom tag wrong when hand-assembling tuples.
 * - Returning a typed enum keeps the surface Phoenix-native while improving correctness and
 *   IDE support in Haxe.
 *
 * HOW
 * - `Noreply(socket)` compiles to `{:noreply, socket}`
 * - `Reply(reply, socket)` compiles to `{:reply, reply, socket}`
 * - `Stop(reason, socket)` compiles to `{:stop, reason, socket}`
 *
 * EXAMPLES
 * Haxe:
 *   public static function handle_in(event: String, payload: Term, socket: Term): ReplyResult<Term> {
 *     return Noreply(socket);
 *   }
 * Elixir:
 *   def handle_in(_, _, socket), do: {:noreply, socket}
 */
enum ReplyResult<TSocket> {
    Noreply(socket: TSocket);
    Reply(reply: Term, socket: TSocket);
    Stop(reason: Term, socket: TSocket);
}

#end

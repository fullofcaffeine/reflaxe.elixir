package phoenix.types;

import elixir.types.Atom;

/**
 * Typed LiveView assign key token.
 *
 * WHAT
 * - Models a Phoenix assign key as a typed token: `AssignKey<TAssigns, TValue>`.
 *
 * WHY
 * - `LiveSocket.assign(_.field, value)` used macro `Expr` arguments, which are not typed
 *   call-site values in the same way as regular typed expressions.
 * - A typed key token makes key/value pairing explicit in function signatures and enforces
 *   that value/updater/default function types match the selected key.
 *
 * HOW
 * - Runtime representation is still an `Atom` (zero runtime overhead).
 * - The type parameters are phantom markers used only by the type checker.
 * - Preferred key generation is `phoenix.AssignKeys.of(MyAssigns)`.
 * - `@:build(phoenix.macros.AssignKeysBuilder.build(...))` remains available when you
 *   want static key constants on a dedicated class.
 *
 * EXAMPLES
 * Haxe:
 *   var keys = phoenix.AssignKeys.of(CounterAssigns);
 *   socket.assignKey(keys.count, 0);
 *   socket.updateKey(keys.count, (n) -> n + 1);
 *
 * Elixir:
 *   assign(socket, :count, 0)
 *   update(socket, :count, &(&1 + 1))
 */
abstract AssignKey<TAssigns, TValue>(Atom) to Atom {}

package client.extern;

/**
 * PhoenixSocket
 *
 * WHAT
 * - Extern for the browser `Socket` constructor exported by the `phoenix` npm package.
 *
 * WHY
 * - `Phoenix.LiveView.LiveSocket` expects the Socket constructor as an argument.
 * - This enables fully-typed LiveView bootstrapping from Haxe (compiled via Genes), without raw JS.
 *
 * HOW
 * - Used as the 2nd argument when constructing `PhoenixLiveSocket`.
 * - We keep it intentionally minimal: the todo-app never instantiates Socket directly.
 */
@:jsRequire("phoenix", "Socket")
extern class PhoenixSocket {}


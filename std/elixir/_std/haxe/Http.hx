package haxe;

/**
 * haxe.Http (Elixir target)
 *
 * WHAT
 * - Standard Haxe sys-target alias for `sys.Http`.
 *
 * WHY
 * - User code commonly imports `haxe.Http`, while the BEAM implementation lives
 *   in `sys.Http` to match Haxe's normal stdlib layering.
 */
typedef Http = sys.Http;

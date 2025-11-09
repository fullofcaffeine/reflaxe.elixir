package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * TracePreserve
 *
 * WHAT
 * - Build macro stub (safe no-op by default) intended to rewrite short-form
 *   `trace(v)` calls into `Log.trace(v, infos)` during the build step.
 *
 * WHY
 * - Keeps trace parity and metadata in Elixir outputs without relying on
 *   runtime patches or editing generated `.ex` files.
 *
 * HOW
 * - `build()` is invoked by `@:build(...)` attached via `TraceAttach.attach()`.
 *   This stub purposely returns the input unchanged until the full rewriter is
 *   enabled. It is safe to ship and keeps attachment stable across Haxe 4/5.
 *
 * EXAMPLES
 * Haxe:
 *   trace("hello")
 * Elixir (when the rewriter is enabled):
 *   Log.trace("hello", %{file_name: ..., line_number: ...})
 */
class TracePreserve {
  public static macro function build():Array<haxe.macro.Expr.Field> {
    // No-op stub: return fields unchanged. Real rewrite is implemented in
    // the dedicated pass to avoid band-aids and to keep behavior explicit.
    return null;
  }
}


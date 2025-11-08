package reflaxe.elixir.runtime;

/**
 * Emit
 *
 * WHAT
 * - Extern surface for compiler-internal emission helpers.
 *
 * WHY
 * - Macros may rewrite calls (e.g., haxe.Log.trace) into these helpers so the
 *   Elixir backend can generate idiomatic target code without being affected by
 *   Haxe's `-D no_traces` removal.
 *
 * HOW
 * - This class is `extern`: it has no runtime implementation. The Elixir
 *   backend (CallExprBuilder) recognizes calls to these helpers and emits
 *   appropriate target AST (e.g., Log.trace/2 with metadata map).
 */
extern class Emit {
  /**
   * Compiler-emitted trace with rich position info.
   * @param v          Any value
   * @param file       File name (no directories)
   * @param line       1-based line number
   * @param className  Declaring class name
   * @param methodName Declaring method name
   */
  public static function logTrace(v: Dynamic, file: String, line: Int, className: String, methodName: String): Void;
}


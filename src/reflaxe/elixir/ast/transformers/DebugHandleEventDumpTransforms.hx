package reflaxe.elixir.ast.transformers;

#if ((macro || reflaxe_runtime) && debug_handle_event_dump)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DebugHandleEventDumpTransforms
 *
 * WHAT
 * - Debug-only: dumps handle_event/3 clauses to stdout for specific event names.
 *
 * HOW
 * - Controlled by -D debug_handle_event_dump. No-op otherwise.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DebugHandleEventDumpTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, _, body) if (isHandleEvent3(name, args)):
          var ev = switch (args[0]) { case PLiteral({def: EString(s)}): s; default: ""; };
          if (ev == "set_priority") {
            Sys.println('--- DEBUG handle_event set_priority ---');
            Sys.println(ElixirASTPrinter.printAST(body));
          }
          n;
        default: n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }
}

#end

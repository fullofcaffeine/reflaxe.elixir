package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * DebugDumpMainBodyTransforms
 *
 * WHAT
 * - (Documented in-file; see the existing code below.)
 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.
 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.
 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */

class DebugDumpMainBodyTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    #if debug_case_hoist
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case EModule(name, _, body):
          if (name == "Main") {
          }
        case EDef(name, args, guards, body):
          if (name == "main") {
            // DEBUG: Sys.println('[DebugDumpMain] Found def main/0; dumping body:\n' + ElixirASTPrinter.print(body, 0));
          }
        default:
      }
      return n;
    });
    #else
    return ast;
    #end
  }
}

#end


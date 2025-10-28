package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

class DebugDumpMainBodyTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    #if debug_case_hoist
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case EModule(name, _, body):
          if (name == "Main") {
            Sys.println('[DebugDumpMain] Visiting module Main; body size=' + body.length);
          }
        case EDef(name, args, guards, body):
          if (name == "main") {
            Sys.println('[DebugDumpMain] Found def main/0; dumping body:\n' + ElixirASTPrinter.print(body, 0));
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


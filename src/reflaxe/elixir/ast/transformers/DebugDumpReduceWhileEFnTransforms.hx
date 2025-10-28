package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

class DebugDumpReduceWhileEFnTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    #if debug_reduce_dump
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case ERemoteCall({def: EVar("Enum")}, "reduce_while", args) if (args != null && args.length >= 3):
          var fnArg = args[2];
          switch (fnArg.def) {
            case EFn(clauses):
              for (cl in clauses) {
                #if sys Sys.println('[DebugReduceDump] EFn body: ' + ElixirASTPrinter.print(cl.body, 0)); #end
              }
            default:
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


package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

class DebugScanAssignChainsTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    #if debug_scan_assign
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case EBinary(Match, left, {def: EBinary(Match, left2, rhs)}):
        case EMatch(pat, {def: EBinary(Match, left3, rhs3)}):
        case EMatch(pat2, {def: EMatch(pat3, rhs4)}):
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


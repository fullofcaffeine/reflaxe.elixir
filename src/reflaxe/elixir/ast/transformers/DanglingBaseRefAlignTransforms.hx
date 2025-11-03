package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * DanglingBaseRefAlignTransforms
 *
 * WHAT
 * - Within a function body, if a base variable `name` appears as EVar but has
 *   no prior definition, and a prior definition exists for `_name`, rewrite the
 *   reference to `_name`.
 */
class DanglingBaseRefAlignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = alignInBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = alignInBody(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function alignInBody(body: ElixirAST): ElixirAST {
    // First pass: collect all binders
    var allUnders:Map<String,Bool> = new Map(); // names with leading _ present anywhere
    var allDefined:Map<String,Bool> = new Map();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) {
        case EBinary(Match, left, _):
          switch (left.def) { case EVar(n): allDefined.set(n, true); if (n.length>1 && n.charAt(0)=='_') allUnders.set(n, true); default: }
        case EMatch(PVar(n2), _): allDefined.set(n2, true); if (n2.length>1 && n2.charAt(0)=='_') allUnders.set(n2, true);
        default:
      }
    });
    // Second pass: rewrite any EVar(base) to _base if base is not defined and _base exists
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v):
          var base = v;
          var underscoreName = "_" + base;
          if (!allDefined.exists(base) && allUnders.exists(underscoreName))
            makeASTWithMeta(EVar(underscoreName), x.metadata, x.pos)
          else x;
        default: x;
      }
    });
  }
}

#end

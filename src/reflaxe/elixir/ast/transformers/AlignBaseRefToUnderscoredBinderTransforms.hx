package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AlignBaseRefToUnderscoredBinderTransforms
 *
 * WHAT
 * - When a block introduces a local underscored binder like `_filter = ...`
 *   and later the body references `filter` (base name) without any definition
 *   of `filter`, rewrite those references to `_filter`.
 *
 * WHY
 * - Late hygiene passes can underscore temp extractions while earlier code
 *   still refers to their base name. This aligns references without relying
 *   on application-specific names.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
  class AlignBaseRefToUnderscoredBinderTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var underscored:Map<String,String> = new Map(); // base -> _base
    var defined:Map<String,Bool> = new Map();

    for (s in stmts) {
      // discover binders
      switch (s.def) {
        case EBinary(Match, left, _):
          switch (left.def) {
            case EVar(n) if (n != null && n.length > 1 && n.charAt(0) == "_"):
              var base = n.substr(1); if (!defined.exists(base)) underscored.set(base, n);
              defined.set(n, true);
            case EVar(n2) if (n2 != null): defined.set(n2, true);
            default:
          }
        case EMatch(pat, _):
          switch (pat) { case PVar(pn) if (pn != null): defined.set(pn, true); default: }
        default:
      }
      // rewrite references within this statement using current map
      var rewritten = ElixirASTTransformer.transformNode(s, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(v) if (v != null && !defined.exists(v) && underscored.exists(v)):
            makeASTWithMeta(EVar(underscored.get(v)), x.metadata, x.pos);
          default: x;
        }
      });
      out.push(rewritten);
    }
    return out;
  }
}

#end

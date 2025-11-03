package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalUnderscoreBinderPromotionWhenUsedTransforms
 *
 * WHAT
 * - Inside blocks/do bodies, when a local binder is introduced with a leading
 *   underscore (e.g., `_tmp`) and that underscored name is read later, promote
 *   the binder and all reads to the base name (e.g., `tmp`) provided no base
 *   binder exists in the same block.
 *
 * WHY
 * - Prevents Elixir warnings about using underscored variables while keeping
 *   the code idiomatic and readable.
 */
  class LocalUnderscoreBinderPromotionWhenUsedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(promote(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(promote(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function promote(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var defined:Map<String,Bool> = new Map();
    var unders:Map<String,Bool> = new Map(); // underscored binder names

    // First scan: collect definitions
    for (s in stmts) {
      switch (s.def) {
        case EBinary(Match, left, _):
          switch (left.def) { case EVar(n): defined.set(n, true); default: }
        case EMatch(pat, _):
          switch (pat) { case PVar(n2): defined.set(n2, true); default: }
        default:
      }
    }
    // Determine promotable names: underscored that are referenced later and base not defined
    var toPromote:Map<String,String> = new Map(); // _name -> name
    for (i in 0...stmts.length) {
      switch (stmts[i].def) {
        case EBinary(Match, left, _):
          switch (left.def) {
            case EVar(n) if (n.length > 1 && n.charAt(0) == "_"):
              var base = n.substr(1);
              if (!defined.exists(base) && usedLaterVar(stmts, i+1, n)) toPromote.set(n, base);
            default:
          }
        case EMatch(pat, _):
          switch (pat) {
            case PVar(n2) if (n2.length > 1 && n2.charAt(0) == "_"):
              var base2 = n2.substr(1);
              if (!defined.exists(base2) && usedLaterVar(stmts, i+1, n2)) toPromote.set(n2, base2);
            default:
          }
        default:
      }
    }
    if (toPromote.keys().hasNext() == false) return stmts;
    // Second pass: apply renames inside the block
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      var rewritten = ElixirASTTransformer.transformNode(s, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(v) if (toPromote.exists(v)):
            makeASTWithMeta(EVar(toPromote.get(v)), x.metadata, x.pos);
          case EBinary(Match, left, rhs):
            switch (left.def) {
              case EVar(v2) if (toPromote.exists(v2)):
                makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(toPromote.get(v2)), left.metadata, left.pos), rhs), x.metadata, x.pos);
              default: x;
            }
          case EMatch(PVar(pn), rhs2) if (toPromote.exists(pn)):
            makeASTWithMeta(EMatch(PVar(toPromote.get(pn)), rhs2), x.metadata, x.pos);
          default: x;
        }
      });
      out.push(rewritten);
    }
    return out;
  }

  static function usedLaterVar(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end

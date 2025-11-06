package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropUnusedSimpleAliasToUnderscoreTransforms
 *
 * WHAT
 * - Converts trivial alias assignments like `tmp = value` to `_ = value` when `tmp` is not
 *   referenced later in the enclosing block.
 *
 * WHY
 * - Hygiene/aliasing passes may introduce helper locals (e.g., `n2 = value`, `x3 = n`) to
 *   stabilize shapes during transformation. When those locals are not subsequently referenced,
 *   they should be discarded to avoid numeric-suffix variables and warnings-as-errors.
 *
 * HOW
 * - For each statement in EBlock/EDo: if it is an assignment with a simple LHS variable and
 *   RHS that is a simple expression (var, atom, number, string, remote/local call) and the
 *   LHS is not used later in the same container, rewrite the LHS to `_`.
 */
class DropUnusedSimpleAliasToUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s2 = s;
      switch (s.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs) if (isSimple(rhs) && hasNumericSuffix(lhs) && !usedLater(stmts, i+1, lhs)):
          s2 = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), s.metadata, s.pos);
        case EMatch(PVar(lhs2), rhs2) if (isSimple(rhs2) && hasNumericSuffix(lhs2) && !usedLater(stmts, i+1, lhs2)):
          s2 = makeASTWithMeta(EMatch(PVar("_"), rhs2), s.metadata, s.pos);
        default:
      }
      out.push(s2);
    }
    return out;
  }

  static function isSimple(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_)|EString(_)|EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EAtom(_): true;
      case ERemoteCall(_,_,_)|ECall(_,_,_): true;
      case EParen(inner): isSimple(inner);
      default: false;
    }
  }

  static inline function hasNumericSuffix(name:String): Bool {
    if (name == null) return false;
    var re = ~/^(.+?)(\d+)$/;
    return re.match(name);
  }

  static function usedLater(stmts:Array<ElixirAST>, from:Int, name:String): Bool {
    if (name == null || name == "_") return false;
    var found = false;
    for (j in from...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(n: ElixirAST) {
        switch (n.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end

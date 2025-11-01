package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalUnderscoreGenericPromotionTransforms
 *
 * WHAT
 * - Promotes local binders with a leading underscore (e.g., `_todo_id`) to their
 *   non-underscored form (`todo_id`) when the binder is actually referenced in the
 *   same block/do body.
 *
 * WHY
 * - Elixir warns when underscored variables are used. When the variable is truly
 *   used (not ignored), it should not be prefixed with `_`.
 *
 * HOW
 * - For EBlock and EDo bodies, walk sequential statements and when encountering
 *   an assignment to `_name`, check for any subsequent reference to `_name` in the
 *   current body. If found, rewrite the binder to `name`.
 */
class LocalUnderscoreGenericPromotionTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          makeASTWithMeta(EDefp(name2, args2, guards2, rewriteBody(body2)), n.metadata, n.pos);
        case EFn(clauses):
          var outClauses = [];
          for (cl in clauses) outClauses.push({ args: cl.args, guard: cl.guard, body: rewriteBody(cl.body) });
          makeASTWithMeta(EFn(outClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(rewriteSeq(stmts)), body.metadata, body.pos);
      case EDo(stmts2):
        makeASTWithMeta(EDo(rewriteSeq(stmts2)), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function rewriteSeq(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar(b), rhs) if (isUnderscored(b) && usedLater(stmts, i, b)):
          makeASTWithMeta(EMatch(PVar(trim(b)), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar(b2)}, rhs2) if (isUnderscored(b2) && usedLater(stmts, i, b2)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar(trim(b2))), rhs2), s.metadata, s.pos);
        default:
          s;
      };
      out.push(s1);
    }
    return out;
  }

  static inline function isUnderscored(name:String):Bool {
    return name != null && name.length > 1 && name.charAt(0) == '_';
  }
  static inline function trim(name:String):String {
    return isUnderscored(name) ? name.substr(1) : name;
  }
  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    function scan(n:ElixirAST) {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v) if (v == name): found = true;
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
        case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
        case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
        case EField(obj,_): scan(obj);
        case EAccess(obj2,key): scan(obj2); scan(key);
        default:
      }
    }
    // Scan current statement’s RHS and subsequent statements
    if (start < stmts.length) scan(stmts[start]);
    for (j in (start+1)...stmts.length) if (!found) scan(stmts[j]);
    return found;
  }
}

#end


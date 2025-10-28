package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SwitchReturnSanitizerTransforms
 *
 * WHAT
 * - Sanitize blocks that end by returning a variable previously assigned to a
 *   case expression. Inline the case expression at the tail position and drop
 *   the redundant assignment.
 *
 * WHY
 * - Some lowering paths create a temp/alias for case results (not the
 *   switch_result_* variant) and later return only the alias. Preserving the
 *   case in return position avoids undefined returns after late folds and
 *   matches intended snapshot shapes for direct switch returns.
 *
 * HOW
 * - For EDef/EDefp bodies that are EBlock([... statements ..., EVar(name)]):
 *   - Scan statements backwards to find the last assignment to `name` where
 *     RHS is ECase(_, _).
 *   - If found, replace trailing `EVar(name)` with that ECase and remove that
 *     assignment statement.
 */
class SwitchReturnSanitizerTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, sanitizeBlock(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          makeASTWithMeta(EDefp(name, args, guards, sanitizeBlock(body)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function sanitizeBlock(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts) if (stmts != null && stmts.length >= 2):
        var last = stmts[stmts.length - 1];
        var retName: Null<String> = switch (last.def) { case EVar(v): v; default: null; };
        if (retName == null) return body;
        // Only inline when the alias is used solely as the trailing return value
        var usages = countVarUsages(stmts, retName);
        if (usages > 1) return body;
        var idx = -1;
        var rhsCase: ElixirAST = null;
        // search backwards for last assignment to retName with ECase RHS
        for (i in 0...stmts.length - 1) {
          var j = (stmts.length - 2) - i;
          switch (stmts[j].def) {
            case EMatch(p, rhs):
              switch (p) { case PVar(n) if (n == retName):
                  switch (rhs.def) { case ECase(_, _): idx = j; rhsCase = rhs; default: }
                default: }
            case EBinary(Match, l, rhs2):
              var ln: Null<String> = switch (l.def) { case EVar(n): n; default: null; };
              if (ln != null && ln == retName) switch (rhs2.def) { case ECase(_, _): idx = j; rhsCase = rhs2; default: }
            default:
          }
          if (idx != -1) break;
        }
        if (idx == -1 || rhsCase == null) return body;
        var out = [];
        for (k in 0...stmts.length - 1) if (k != idx) out.push(stmts[k]);
        out.push(rhsCase);
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function countVarUsages(stmts: Array<ElixirAST>, name: String): Int {
    var count = 0;
    for (i in 0...stmts.length) {
      var s = stmts[i];
      // Count only value references (EVar) not on LHS of a match
      function walk(n: ElixirAST): Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
          case EVar(v) if (v == name): count++;
          case EMatch(p, r): walk(r); // skip LHS
          case EBinary(Match, l, r): walk(r);
          case EBlock(es) | EDo(es): for (e in es) walk(e);
          case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
          case ECase(expr, cs): walk(expr); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
          case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
          case ERemoteCall(m,_,as): walk(m); for (a in as) walk(a);
          case ETuple(es) | EList(es): for (e in es) walk(e);
          case EMap(ps): for (p in ps) { walk(p.key); walk(p.value); }
          default:
        }
      }
      walk(s);
    }
    return count;
  }
}

#end

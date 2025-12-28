package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseUnderscoreAssignHoistAnyTransforms
 *
 * WHAT
 * - Generic, shape-only rewrite for `_ = case <scrut> do ... end` →
 *   `tmp = <scrut>; case tmp do ... end`.
 *
 * WHY
 * - Some pipelines still produce a discarded case expression in statement position.
 *   Hoisting the scrutinee to a named local matches idiomatic Elixir and our snapshots.
 *
 * HOW
 * - Matches EBinary(Match, EVar("_"), ECase(scrut, clauses)) anywhere.
 * - Picks a non-colliding local name from ["parsed_result","value","result_value"].
 * - Emits EBlock([var = scrut, case var do ... end]).
 * - Runs ultra-late so no later pass reverts it.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseUnderscoreAssignHoistAnyTransforms {
  static function pickName(env: Map<String,Bool>): String {
    var cands = ["parsed_result","value","result_value"];
    for (c in cands) if (!env.exists(c)) return c;
    // last-resort unique but descriptive; no numeric suffixes
    var alt = "parsed_value";
    var idx = 0;
    while (env.exists(alt)) { alt = "parsed_value_alt" + (idx == 0 ? "" : "_x"); idx++; if (idx > 2) break; }
    return alt;
  }

  static function collectLocals(n: ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function walk(x: ElixirAST): Void {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EBinary(Match, {def: EVar(v)}, _): m.set(v, true);
        case EMatch(PVar(v), _): m.set(v, true);
        case EBlock(ss): for (s in ss) walk(s);
        case EDo(ss2): for (s in ss2) walk(s);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(expr, clauses):
          walk(expr);
          for (c in clauses) walk(c.body);
        case EFn(clauses): for (cl in clauses) walk(cl.body);
        case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
        case ERemoteCall(mo,_,as2): walk(mo); for (a in as2) walk(a);
        case EList(items) | ETuple(items): for (i in items) walk(i);
        case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
        default:
      }
    }
    walk(n);
    return m;
  }

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, {def: EVar("_")}, {def: ECase(scrut, clauses)}):
          var env = collectLocals(n);
          var name = pickName(env);
          var assign = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(name), n.metadata, n.pos), scrut), n.metadata, n.pos);
          var caze = makeASTWithMeta(ECase(makeASTWithMeta(EVar(name), n.metadata, n.pos), clauses), n.metadata, n.pos);
          makeASTWithMeta(EBlock([assign, caze]), n.metadata, n.pos);
        case EMatch(pat, {def: ECase(scr2, cls2)}):
          // Handle pattern-style match as assignment
          var isDiscard = switch (pat) { case PVar("_") | PPin(PVar("_")): true; default: false; };
          if (isDiscard) {
            var env2 = collectLocals(n);
            var nname = pickName(env2);
            var assign2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(nname), n.metadata, n.pos), scr2), n.metadata, n.pos);
            var caze2 = makeASTWithMeta(ECase(makeASTWithMeta(EVar(nname), n.metadata, n.pos), cls2), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assign2, caze2]), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }
}

#end

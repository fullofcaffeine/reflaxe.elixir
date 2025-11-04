package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreVarUsageFixTransforms
 *
 * WHAT
 * - Renames variables that start with an underscore (e.g., `_socket`) to their
 *   non-underscored form (e.g., `socket`) when they are used in expression
 *   positions. This avoids "underscored variable used after being set" warnings
 *   under MIX_ENV=test with warnings-as-errors.
 *
 * WHY
 * - Prior hygiene passes sometimes prefixed variables with `_` to silence
 *   unused-variable warnings, but later transforms reintroduced usages of those
 *   variables, causing warnings. This pass resolves such cases generically,
 *   without app coupling.
 *
 * HOW
 * - Walks EDef/EDefp/EFn/EBlock/EDo bodies. For each block, collect candidates:
 *   variables whose name starts with `_` and that appear in expression context.
 *   Then rewrite all occurrences in that block scope to the de-underscored name.
 */
class UnderscoreVarUsageFixTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewrite(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          makeASTWithMeta(EDefp(name, args, guards, rewrite(body)), n.metadata, n.pos);
        case EFn(clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ args: cl.args, guard: cl.guard, body: rewrite(cl.body) });
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    // Collect underscore vars that are used
    var used = new Map<String,Bool>();
    function collect(x: ElixirAST, inPattern: Bool): Void {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EVar(v) if (!inPattern && v != null && v.length > 1 && v.charAt(0) == '_'):
          used.set(v, true);
        case EPin(inner): collect(inner, false);
        case EBinary(_, l, r): collect(l, false); collect(r, false);
        case EMatch(p, rhs): collect(rhs, false); // pattern ignored
        case EBlock(ss): for (s in ss) collect(s, false);
        case EDo(ss2): for (s in ss2) collect(s, false);
        case EIf(c,t,e): collect(c, false); collect(t, false); if (e != null) collect(e, false);
        case ECase(expr, clauses):
          collect(expr, false);
          for (cl in clauses) { if (cl.guard != null) collect(cl.guard, false); collect(cl.body, false); }
        case ECall(t,_,as): if (t != null) collect(t, false); if (as != null) for (a in as) collect(a, false);
        case ERemoteCall(t2,_,as2): collect(t2, false); if (as2 != null) for (a in as2) collect(a, false);
        case EField(obj,_): collect(obj, false);
        case EAccess(tgt,key): collect(tgt, false); collect(key, false);
        case EList(el): for (e in el) collect(e, false);
        case ETuple(el): for (e in el) collect(e, false);
        case EKeywordList(pairs): for (p in pairs) { collect(p.value, false); }
        case EMap(pairs): for (p in pairs) { collect(p.key, false); collect(p.value, false); }
        default:
      }
    }
    collect(body, false);

    if (used.keys().hasNext() == false) return body;

    function rename(x: ElixirAST, inPattern: Bool): ElixirAST {
      if (x == null || x.def == null) return x;
      return switch (x.def) {
        case EVar(v) if (!inPattern && used.exists(v)):
          var nv = v.substr(1); // drop leading underscore
          makeASTWithMeta(EVar(nv), x.metadata, x.pos);
        case EMatch(p, rhs):
          // Rename in RHS only; keep pattern vars as-is
          makeASTWithMeta(EMatch(p, rename(rhs, false)), x.metadata, x.pos);
        case EBinary(op, l, r): makeASTWithMeta(EBinary(op, rename(l, false), rename(r, false)), x.metadata, x.pos);
        case EBlock(ss):
          var out = [];
          for (s in ss) out.push(rename(s, false));
          makeASTWithMeta(EBlock(out), x.metadata, x.pos);
        case EDo(ss2):
          var out2 = [];
          for (s in ss2) out2.push(rename(s, false));
          makeASTWithMeta(EDo(out2), x.metadata, x.pos);
        case EIf(c,t,e):
          makeASTWithMeta(EIf(rename(c, false), rename(t, false), e != null ? rename(e, false) : null), x.metadata, x.pos);
        case ECase(expr, clauses):
          var ncs = [];
          for (cl in clauses) ncs.push({ pattern: cl.pattern, guard: cl.guard != null ? rename(cl.guard, false) : null, body: rename(cl.body, false) });
          makeASTWithMeta(ECase(rename(expr, false), ncs), x.metadata, x.pos);
        case ECall(t, m, as):
          var nt = t != null ? rename(t, false) : null;
          var nas = [];
          if (as != null) for (a in as) nas.push(rename(a, false));
          makeASTWithMeta(ECall(nt, m, nas), x.metadata, x.pos);
        case ERemoteCall(t2, m2, as2):
          var nt2 = rename(t2, false);
          var nas2 = [];
          if (as2 != null) for (a in as2) nas2.push(rename(a, false));
          makeASTWithMeta(ERemoteCall(nt2, m2, nas2), x.metadata, x.pos);
        case EField(obj, f): makeASTWithMeta(EField(rename(obj, false), f), x.metadata, x.pos);
        case EAccess(tgt, key): makeASTWithMeta(EAccess(rename(tgt, false), rename(key, false)), x.metadata, x.pos);
        case EList(el):
          var el2 = [for (e in el) rename(e, false)];
          makeASTWithMeta(EList(el2), x.metadata, x.pos);
        case ETuple(el):
          var el3 = [for (e in el) rename(e, false)];
          makeASTWithMeta(ETuple(el3), x.metadata, x.pos);
        case EKeywordList(pairs):
          var ps = [];
          for (p in pairs) ps.push({ key: p.key, value: rename(p.value, false) });
          makeASTWithMeta(EKeywordList(ps), x.metadata, x.pos);
        case EMap(pairs):
          var mp = [];
          for (p in pairs) mp.push({ key: rename(p.key, false), value: rename(p.value, false) });
          makeASTWithMeta(EMap(mp), x.metadata, x.pos);
        default:
          x;
      }
    }
    return rename(body, false);
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnBinderAlignToUndefinedRefTransforms
 *
 * WHAT
 * - In single-arg anonymous functions, if there is a single undefined simple
 *   variable referenced in the body, rename the binder to that undefined name
 *   and rewrite binder references accordingly.
 *
 * WHY
 * - Some loop builders fall back to a generic binder name (e.g., "item").
 *   When the original body relies on a specific name (e.g., "todo"), later
 *   passes can leave it undefined. Unifying the binder name to the intended
 *   body reference is shape-safe when the undefined name is unique.
 *
 * HOW
 * - For each EFn clause with exactly one PVar binder:
 *   1) Collect declared names inside the clause (including outer-scope names, binder, and inner LHS binds).
 *   2) Collect referenced simple EVar names and compute undefined.
 *   3) If undefined.length == 1, let u be that name. Rename binder argName->u and
 *      rewrite EVar(argName) -> EVar(u) in the clause body.
 *
 * IMPORTANT
 * - This pass must be scope-aware: variables that are free (declared in the
 *   enclosing def/defp) are NOT "undefined" for the inner EFn. Renaming the
 *   binder to a free variable captures and shadows outer values, breaking
 *   semantics (e.g., list update-by-id patterns that compare against a function
 *   parameter like `todo`).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EFnBinderAlignToUndefinedRefTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    var empty = new Map<String,Bool>();
    return rewrite(ast, empty);
  }

  static function rewrite(n: ElixirAST, outerDeclared: Map<String,Bool>): ElixirAST {
    if (n == null || n.def == null) return n;

    return switch (n.def) {
      case EDef(name, args, guards, body):
        var nextOuter = extendOuterWithArgs(outerDeclared, args);
        var newBody = rewrite(body, nextOuter);
        makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);

      case EDefp(name, args, guards, body):
        var nextOuter = extendOuterWithArgs(outerDeclared, args);
        var newBody = rewrite(body, nextOuter);
        makeASTWithMeta(EDefp(name, args, guards, newBody), n.metadata, n.pos);

      case EFn(clauses):
        var newClauses = [];
        for (cl in clauses) {
          var clauseOuter = extendOuterWithArgs(outerDeclared, cl.args);
          var rewrittenBody = rewrite(cl.body, clauseOuter);

          var argName: Null<String> = null;
          if (cl.args != null && cl.args.length == 1) {
            switch (cl.args[0]) { case PVar(a): argName = a; default: }
          }
          if (argName == null) {
            newClauses.push({ args: cl.args, guard: cl.guard, body: rewrittenBody });
            continue;
          }

          var declared = cloneMap(clauseOuter);
          function collectPat(p:EPattern):Void {
            switch (p) {
              case PVar(v): declared.set(v, true);
              case PTuple(es) | PList(es): for (e in es) collectPat(e);
              case PCons(h,t): collectPat(h); collectPat(t);
              case PMap(kvs): for (kv in kvs) collectPat(kv.value);
              case PStruct(_, fs): for (f in fs) collectPat(f.value);
              case PPin(inner): collectPat(inner);
              default:
            }
          }

          // Helper to detect local variable names (exclude modules/captures)
          inline function isLocalVarName(s:String):Bool {
            if (s == null || s.length == 0) return false;
            var c = s.charAt(0);
            var isUpper = c == c.toUpperCase() && c != c.toLowerCase();
            if (isUpper) return false;
            if (s.indexOf('.') != -1) return false;
            return true;
          }

          // Scan clause body for declared and referenced names
          var referenced = new Map<String,Bool>();
          ElixirASTTransformer.transformNode(rewrittenBody, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
              case EMatch(p, _): collectPat(p);
              case EBinary(Match, l, _):
                switch (l.def) { case EVar(v): declared.set(v, true); default: }
              case ECase(_, cs): for (c in cs) collectPat(c.pattern);
              case EVar(v) if (isLocalVarName(v)): referenced.set(v, true);
              default:
            }
            return x;
          });

          // Gather undefined refs used as field receivers (exclude outer scope)
          var fieldReceivers = new Map<String,Bool>();
          ElixirASTTransformer.transformNode(rewrittenBody, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
              case EField({def: EVar(v)}, _ ) if (isLocalVarName(v) && !declared.exists(v)):
                // If v exists in outerDeclared, it's a legitimate free var; do not capture it.
                if (!outerDeclared.exists(v)) fieldReceivers.set(v, true);
                x;
              default:
                x;
            };
          });

	          var receiverList = [for (k in fieldReceivers.keys()) k];
	          if (receiverList.length == 1) {
	            var u = receiverList[0];
	            var receiverAlignedBody = ElixirASTTransformer.transformNode(rewrittenBody, function(x: ElixirAST): ElixirAST {
	              return switch (x.def) {
	                case EVar(v) if (v == argName): makeASTWithMeta(EVar(u), x.metadata, x.pos);
	                default: x;
	              }
	            });
	            newClauses.push({ args: [PVar(u)], guard: cl.guard, body: receiverAlignedBody });
	          } else {
	            newClauses.push({ args: cl.args, guard: cl.guard, body: rewrittenBody });
	          }
        }
        makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);

      case EBlock(stmts):
        var out = [for (s in stmts) rewrite(s, outerDeclared)];
        makeASTWithMeta(EBlock(out), n.metadata, n.pos);

      case EDo(stmts):
        var out = [for (s in stmts) rewrite(s, outerDeclared)];
        makeASTWithMeta(EDo(out), n.metadata, n.pos);

      case EIf(cond, thenB, elseB):
        var nc = rewrite(cond, outerDeclared);
        var nt = rewrite(thenB, outerDeclared);
        var ne = elseB != null ? rewrite(elseB, outerDeclared) : null;
        makeASTWithMeta(EIf(nc, nt, ne), n.metadata, n.pos);

      case ECase(expr, clauses):
        var ne = rewrite(expr, outerDeclared);
        var newClauses:Array<ECaseClause> = [];
        for (cl in clauses) {
          newClauses.push({
            pattern: cl.pattern,
            guard: cl.guard != null ? rewrite(cl.guard, outerDeclared) : null,
            body: rewrite(cl.body, outerDeclared)
          });
        }
        makeASTWithMeta(ECase(ne, newClauses), n.metadata, n.pos);

      case ECall(target, name, args):
        var nt = target != null ? rewrite(target, outerDeclared) : null;
        var na = [for (a in args) rewrite(a, outerDeclared)];
        makeASTWithMeta(ECall(nt, name, na), n.metadata, n.pos);

      case ERemoteCall(target, name, args):
        var nt = rewrite(target, outerDeclared);
        var na = [for (a in args) rewrite(a, outerDeclared)];
        makeASTWithMeta(ERemoteCall(nt, name, na), n.metadata, n.pos);

      case EField(obj, field):
        makeASTWithMeta(EField(rewrite(obj, outerDeclared), field), n.metadata, n.pos);

      case EAccess(obj, key):
        makeASTWithMeta(EAccess(rewrite(obj, outerDeclared), rewrite(key, outerDeclared)), n.metadata, n.pos);

      case EKeywordList(pairs):
        var np = [for (p in pairs) { key: p.key, value: rewrite(p.value, outerDeclared) }];
        makeASTWithMeta(EKeywordList(np), n.metadata, n.pos);

      case EMap(pairs):
        var np = [for (p in pairs) { key: rewrite(p.key, outerDeclared), value: rewrite(p.value, outerDeclared) }];
        makeASTWithMeta(EMap(np), n.metadata, n.pos);

      case EStruct(mod, fields):
        var nf = [for (f in fields) { key: f.key, value: rewrite(f.value, outerDeclared) }];
        makeASTWithMeta(EStruct(mod, nf), n.metadata, n.pos);

      case EStructUpdate(base, fields):
        var nb = rewrite(base, outerDeclared);
        var nf = [for (f in fields) { key: f.key, value: rewrite(f.value, outerDeclared) }];
        makeASTWithMeta(EStructUpdate(nb, nf), n.metadata, n.pos);

      case ETuple(elems):
        makeASTWithMeta(ETuple([for (e in elems) rewrite(e, outerDeclared)]), n.metadata, n.pos);

      case EList(elems):
        makeASTWithMeta(EList([for (e in elems) rewrite(e, outerDeclared)]), n.metadata, n.pos);

      case EParen(inner):
        makeASTWithMeta(EParen(rewrite(inner, outerDeclared)), n.metadata, n.pos);

      case EBinary(op, l, r):
        makeASTWithMeta(EBinary(op, rewrite(l, outerDeclared), rewrite(r, outerDeclared)), n.metadata, n.pos);

      case EMatch(pat, rhs):
        makeASTWithMeta(EMatch(pat, rewrite(rhs, outerDeclared)), n.metadata, n.pos);

      case EUnary(op, v):
        makeASTWithMeta(EUnary(op, rewrite(v, outerDeclared)), n.metadata, n.pos);

      case EPipe(l, r):
        makeASTWithMeta(EPipe(rewrite(l, outerDeclared), rewrite(r, outerDeclared)), n.metadata, n.pos);

      case EWith(clauses, doBlock, elseBlock):
        var nclauses = [for (c in clauses) { pattern: c.pattern, expr: rewrite(c.expr, outerDeclared) }];
        var ndo = rewrite(doBlock, outerDeclared);
        var nel = elseBlock != null ? rewrite(elseBlock, outerDeclared) : null;
        makeASTWithMeta(EWith(nclauses, ndo, nel), n.metadata, n.pos);

      case EReceive(clauses, after):
        var nclauses = [for (c in clauses) { pattern: c.pattern, guard: c.guard, body: rewrite(c.body, outerDeclared) }];
        var nafter = after != null ? { timeout: after.timeout, body: rewrite(after.body, outerDeclared) } : null;
        makeASTWithMeta(EReceive(nclauses, nafter), n.metadata, n.pos);

      case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
        var nb = rewrite(body, outerDeclared);
        var nr = rescueClauses != null ? [for (c in rescueClauses) { pattern: c.pattern, varName: c.varName, body: rewrite(c.body, outerDeclared) }] : null;
        var nc = catchClauses != null ? [for (c in catchClauses) { kind: c.kind, pattern: c.pattern, body: rewrite(c.body, outerDeclared) }] : null;
        var na = afterBlock != null ? rewrite(afterBlock, outerDeclared) : null;
        var ne = elseBlock != null ? rewrite(elseBlock, outerDeclared) : null;
        makeASTWithMeta(ETry(nb, nr, nc, na, ne), n.metadata, n.pos);

      default:
        n;
    }
  }

  static function extendOuterWithArgs(outer: Map<String,Bool>, args: Array<EPattern>): Map<String,Bool> {
    var out = cloneMap(outer);
    if (args != null) for (a in args) switch (a) {
      case PVar(nm) if (nm != null): out.set(nm, true);
      case PAlias(nm2, _) if (nm2 != null): out.set(nm2, true);
      default:
    }
    return out;
  }

  static function cloneMap(m: Map<String,Bool>): Map<String,Bool> {
    var out = new Map<String,Bool>();
    if (m != null) for (k in m.keys()) out.set(k, m.get(k));
    return out;
  }
}

#end

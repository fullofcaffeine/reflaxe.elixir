package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderArgCollisionAvoidTransforms
 *
 * WHAT
 * - Prevent tuple-pattern binders in case/cond matches from colliding with
 *   function argument names (e.g., `socket`). When a clause binds a variable
 *   that equals any function arg name, rename the binder to a safe, generic
 *   identifier ("payload") and rewrite clause body references accordingly.
 *
 * WHY
 * - Binder collisions shadow function arguments and corrupt subsequent calls
 *   that expect the original arg value, producing runtime errors like
 *   "undefined variable" or wrong-argument shapes.
 * - Example seen in handle_info/2: `{:todo_created, socket}` shadows the
 *   function arg `socket`; the body then references `todo` which was intended
 *   for the tuple payload, yielding undefined variable errors and incorrect
 *   helper calls.
 *
 * HOW
 * - For each def/defp, collect argument names. Traverse case clauses; for each
 *   pattern variable (PVar) that equals an argument name, rename it to
 *   "payload" (or keep original if already safe) and substitute all body and
 *   guard occurrences. Tuple tags are preserved; this is shape-only.
 *
 * EXAMPLES
 * Before:
 *   def handle_info(msg, socket) do
 *     case msg do
 *       {:ok, socket} -> socket
 *     end
 *   end
 * After:
 *   def handle_info(msg, socket) do
 *     case msg do
 *       {:ok, payload} -> payload
 *     end
 *   end
 */
class CaseBinderArgCollisionAvoidTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var argNames = collectArgNames(args);
          var nb = rewriteCaseBinders(body, argNames);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var argNames2 = collectArgNames(args2);
          var nb2 = rewriteCaseBinders(body2, argNames2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collectArgNames(args:Array<EPattern>):Map<String,Bool> {
    var m = new Map<String,Bool>();
    for (a in args) switch (a) {
      case PVar(n) if (n != null && n.length > 0): m.set(n, true);
      default:
    }
    return m;
  }

  static function rewriteCaseBinders(body: ElixirAST, argNames: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          var scrutineeName:Null<String> = switch (expr.def) {
            case EVar(v): v;
            default: null;
          };
          var out:Array<ECaseClause> = [];
          for (c in clauses) out.push(renameCollidingBinders(c, argNames, scrutineeName));
          makeASTWithMeta(ECase(expr, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function renameCollidingBinders(clause:ECaseClause, argNames:Map<String,Bool>, scrutineeName:Null<String>): ECaseClause {
    var renameMap = new Map<String, String>();
    var renamedPattern = renamePattern(clause.pattern, argNames, renameMap, scrutineeName);
    if (!renameMap.keys().hasNext()) return clause;

    var newGuard = clause.guard == null ? null : rewriteVars(clause.guard, renameMap);
    var newBody = rewriteVars(clause.body, renameMap);
    return { pattern: renamedPattern, guard: newGuard, body: newBody };
  }

  static function renamePattern(p:EPattern, argNames:Map<String,Bool>, renameMap:Map<String,String>, scrutineeName:Null<String>): EPattern {
    return switch (p) {
      case PVar(n) if (n != null && argNames.exists(n) && (scrutineeName == null || scrutineeName != n)):
        var nn = safeNameFrom(n);
        renameMap.set(n, nn);
        PVar(nn);
      case PAlias(nm, inner):
        var newNm = nm;
        if (nm != null && argNames.exists(nm) && (scrutineeName == null || scrutineeName != nm)) {
          newNm = safeNameFrom(nm);
          renameMap.set(nm, newNm);
        }
        PAlias(newNm, renamePattern(inner, argNames, renameMap, scrutineeName));
      case PTuple(es):
        PTuple([for (e in es) renamePattern(e, argNames, renameMap, scrutineeName)]);
      case PList(es):
        PList([for (e in es) renamePattern(e, argNames, renameMap, scrutineeName)]);
      case PCons(h, t):
        PCons(renamePattern(h, argNames, renameMap, scrutineeName), renamePattern(t, argNames, renameMap, scrutineeName));
      case PMap(kvs):
        PMap([for (kv in kvs) { key: kv.key, value: renamePattern(kv.value, argNames, renameMap, scrutineeName) }]);
      case PStruct(m, fs):
        PStruct(m, [for (f in fs) { key: f.key, value: renamePattern(f.value, argNames, renameMap, scrutineeName) }]);
      case PBinary(segs):
        PBinary([for (s in segs) { pattern: renamePattern(s.pattern, argNames, renameMap, scrutineeName), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner):
        PPin(renamePattern(inner, argNames, renameMap, scrutineeName));
      default:
        p;
    }
  }

  static inline function safeNameFrom(original:String): String {
    // Descriptive and stable; avoids numeric suffixes.
    return "payload_" + original;
  }

  static function rewriteVars(expr: ElixirAST, renameMap: Map<String,String>): ElixirAST {
    function cloneNameSet(src: Map<String, Bool>): Map<String, Bool> {
      var out = new Map<String, Bool>();
      for (k in src.keys()) out.set(k, true);
      return out;
    }

    function collectPatternBinders(p: EPattern, out: Map<String, Bool>): Void {
      switch (p) {
        case PVar(n) if (n != null && n.length > 0):
          out.set(n, true);
        case PAlias(nm, inner):
          if (nm != null && nm.length > 0) out.set(nm, true);
          collectPatternBinders(inner, out);
        case PTuple(es) | PList(es):
          for (e in es) collectPatternBinders(e, out);
        case PCons(h, t):
          collectPatternBinders(h, out);
          collectPatternBinders(t, out);
        case PMap(kvs):
          for (kv in kvs) collectPatternBinders(kv.value, out);
        case PStruct(_, fs):
          for (f in fs) collectPatternBinders(f.value, out);
        case PBinary(segs):
          for (s in segs) collectPatternBinders(s.pattern, out);
        case PPin(inner):
          collectPatternBinders(inner, out);
        default:
      }
    }

    function collectDeclaredFromStatement(stmt: ElixirAST, out: Map<String, Bool>): Void {
      if (stmt == null || stmt.def == null) return;
      switch (stmt.def) {
        case EMatch(pat, _):
          collectPatternBinders(pat, out);
        case EBinary(Match, {def: EVar(lhs)}, _):
          if (lhs != null && lhs.length > 0) out.set(lhs, true);
        case EBinary(Match, {def: EMatch(pat2, _)}, _):
          collectPatternBinders(pat2, out);
        default:
      }
    }

    function rewriteExpr(node: ElixirAST, shadowed: Map<String, Bool>): ElixirAST {
      if (node == null || node.def == null) return node;
      return switch (node.def) {
        case EVar(v) if (v != null && renameMap.exists(v) && !shadowed.exists(v)):
#if debug_case_binder_arg_collision
          try {
            trace('[CaseBinderArgCollisionAvoid] EVar rename ' + v + ' -> ' + renameMap.get(v));
          } catch (_) {}
#end
          makeASTWithMeta(EVar(renameMap.get(v)), node.metadata, node.pos);

        case ECase(scrut, clauses):
          var nextScrut = rewriteExpr(scrut, shadowed);
          var nextClauses: Array<ECaseClause> = [];
          for (cl in clauses) {
            var clauseScope = cloneNameSet(shadowed);
            collectPatternBinders(cl.pattern, clauseScope);
            var nextGuard = cl.guard == null ? null : rewriteExpr(cl.guard, clauseScope);
            var nextBody = rewriteExpr(cl.body, clauseScope);
            nextClauses.push({ pattern: cl.pattern, guard: nextGuard, body: nextBody });
          }
          makeASTWithMeta(ECase(nextScrut, nextClauses), node.metadata, node.pos);

        case EFn(clauses):
          var nextFnClauses = [];
          for (cl in clauses) {
            var fnScope = cloneNameSet(shadowed);
            for (a in cl.args) collectPatternBinders(a, fnScope);
            var nextGuard = cl.guard == null ? null : rewriteExpr(cl.guard, fnScope);
            var nextBody = rewriteExpr(cl.body, fnScope);
            nextFnClauses.push({ args: cl.args, guard: nextGuard, body: nextBody });
          }
          makeASTWithMeta(EFn(nextFnClauses), node.metadata, node.pos);

        case EBlock(stmts):
          var scope = cloneNameSet(shadowed);
          var outStmts: Array<ElixirAST> = [];
          for (s in stmts) {
            var ns = rewriteExpr(s, scope);
            outStmts.push(ns);
            collectDeclaredFromStatement(ns, scope);
          }
          makeASTWithMeta(EBlock(outStmts), node.metadata, node.pos);

        case EDo(stmts):
          var scopeDo = cloneNameSet(shadowed);
          var outDo: Array<ElixirAST> = [];
          for (s in stmts) {
            var ns = rewriteExpr(s, scopeDo);
            outDo.push(ns);
            collectDeclaredFromStatement(ns, scopeDo);
          }
          makeASTWithMeta(EDo(outDo), node.metadata, node.pos);

        case EMatch(pat, rhs):
          makeASTWithMeta(EMatch(pat, rewriteExpr(rhs, shadowed)), node.metadata, node.pos);

        case EBinary(Match, left, rhs):
          // Never rewrite the LHS; only the RHS expression.
          makeASTWithMeta(EBinary(Match, left, rewriteExpr(rhs, shadowed)), node.metadata, node.pos);

        default:
          ElixirASTTransformer.transformAST(node, function(child:ElixirAST):ElixirAST {
            return rewriteExpr(child, shadowed);
          });
      };
    }

    return rewriteExpr(expr, new Map<String, Bool>());
  }
}

#end

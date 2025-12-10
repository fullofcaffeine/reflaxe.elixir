package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * UnusedVarUnderscoreFinalTransforms
 *
 * WHAT
 * - Late, single-pass hygiene that prefixes truly unused variables with an
 *   underscore to silence Elixir warnings without altering semantics.
 *
 * WHY
 * - LiveView helper injections (e.g., `value = params`, `sort_by = ...`) and
 *   safety binds can flood the generated code with unused variables. Elixir
 *   warns on each, obscuring real issues. We want deterministic, warning-free
 *   output while keeping meaningful bindings intact.
 *
 * HOW
 * - For each def/defp:
 *   1) Collect all declared variable names from params and pattern/LHS binders
 *      (case/receive/with/for/fn/try patterns included).
 *   2) Collect references using VariableUsageCollector (excludes LHS binders).
 *   3) Any declared name (lowercase starter) that is never referenced and does
 *      NOT already start with "_" is marked unused.
 *   4) Rewrite patterns/LHS vars (and any stray EVar occurrences) for unused
 *      names to `"_" + name`.
 * - Leaves already-underscored variables untouched; avoids inventing new base
 *   names or altering referenced bindings.
 */
class UnusedVarUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EDef(name, params, guards, body):
          if (!shouldProcess(name)) return node;
          var nb = process(body, params);
          makeASTWithMeta(EDef(name, params, guards, nb), node.metadata, node.pos);
        case EDefp(name, params, guards, body):
          if (!shouldProcess(name)) return node;
          var nb2 = process(body, params);
          makeASTWithMeta(EDefp(name, params, guards, nb2), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function process(body: ElixirAST, params:Array<EPattern>): ElixirAST {
    // Skip functions that embed raw Elixir; references inside ERaw strings are
    // invisible to the analyzer and renaming would break them.
    if (containsRaw(body)) return body;

    // 1) collect declarations
    var decls = new Map<String,Bool>();
    if (params != null) for (p in params) collectPatternDecls(p, decls);
    collectDecls(body, decls);

    // 2) collect references (excludes binders)
    var refs = VariableUsageCollector.referencedInFunctionScope(body);

    // 3) identify unused
    var unused = new Map<String,Bool>();
    for (k in decls.keys()) {
      if (k == null || k.length == 0) continue;
      if (k.charAt(0) == "_") continue; // already safe
      var c = k.charAt(0);
      if (c != c.toLowerCase()) continue; // skip Module/constant
      if (!refs.exists(k)) unused.set(k, true);
    }
    if (!unused.keys().hasNext()) return body;

    // 4) rewrite
    function rename(name:String):String {
      return (unused.exists(name) && name.charAt(0) != "_") ? "_" + name : name;
    }

    function rewPat(p:EPattern):EPattern {
      return switch (p) {
        case PVar(v): PVar(rename(v));
        case PAlias(v, pat): PAlias(rename(v), rewPat(pat));
        case PTuple(items): PTuple(items.map(rewPat));
        case PList(items): PList(items.map(rewPat));
        case PCons(h, t): PCons(rewPat(h), rewPat(t));
        case PMap(fields): PMap([for (f in fields) { key: f.key, value: rewPat(f.value) }]);
        case PStruct(mod, fields): PStruct(mod, [for (f in fields) { key: f.key, value: rewPat(f.value) }]);
        case PBinary(segs): PBinary([for (s in segs) { pattern: rewPat(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers }]);
        case PPin(inner): PPin(rewPat(inner));
        default: p;
      }
    }

    function rewLhs(lhs:ElixirAST):ElixirAST {
      if (lhs == null || lhs.def == null) return lhs;
      return switch (lhs.def) {
        case EVar(v):
          var nv = rename(v);
          (nv == v) ? lhs : makeASTWithMeta(EVar(nv), lhs.metadata, lhs.pos);
        case EMatch(p, rhs):
          makeASTWithMeta(EMatch(rewPat(p), rhs), lhs.metadata, lhs.pos);
        default:
          lhs;
      }
    }

    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      if (n == null || n.def == null) return n;
      return switch (n.def) {
        case EVar(v):
          var nv = rename(v);
          (nv == v) ? n : makeASTWithMeta(EVar(nv), n.metadata, n.pos);
        case EMatch(p, rhs):
          makeASTWithMeta(EMatch(rewPat(p), rhs), n.metadata, n.pos);
        case EBinary(Match, left, rhs):
          makeASTWithMeta(EBinary(Match, rewLhs(left), rhs), n.metadata, n.pos);
        case EFn(clauses):
          var cls = [for (c in clauses) {
            args: [for (a in c.args) rewPat(a)],
            guard: c.guard,
            body: c.body
          }];
          makeASTWithMeta(EFn(cls), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [for (cl in clauses) {
            pattern: rewPat(cl.pattern),
            guard: cl.guard,
            body: cl.body
          }];
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        case EReceive(clauses, after):
          var newClausesR = [for (cl in clauses) { pattern: rewPat(cl.pattern), body: cl.body }];
          makeASTWithMeta(EReceive(newClausesR, after), n.metadata, n.pos);
        case EWith(clauses, doBlock, elseBlock):
          var newClausesW = [for (cl in clauses) { pattern: rewPat(cl.pattern), expr: cl.expr }];
          makeASTWithMeta(EWith(newClausesW, doBlock, elseBlock), n.metadata, n.pos);
        case EFor(gens, filters, forBody, into, uniq):
          var newGens = [for (g in gens) { pattern: rewPat(g.pattern), expr: g.expr }];
          makeASTWithMeta(EFor(newGens, filters, forBody, into, uniq), n.metadata, n.pos);
        case ETry(bodyT, rescueClauses, catchClauses, afterBlock, elseBlock):
          var newRescue = (rescueClauses == null) ? null : [for (rc in rescueClauses) { pattern: rewPat(rc.pattern), varName: rc.varName, body: rc.body }];
          var newCatch = (catchClauses == null) ? null : [for (cc in catchClauses) { kind: cc.kind, pattern: rewPat(cc.pattern), body: cc.body }];
          makeASTWithMeta(ETry(bodyT, newRescue, newCatch, afterBlock, elseBlock), n.metadata, n.pos);
        default:
          n;
      };
    });
  }

  static function collectDecls(body: ElixirAST, out: Map<String,Bool>): Void {
    ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(pat, _): collectPatternDecls(pat, out);
        case EBinary(Match, lhs, _):
          switch (lhs.def) {
            case EVar(v): out.set(v, true);
            case EMatch(p2, _): collectPatternDecls(p2, out);
            default:
          }
        case ECase(_, clauses): for (cl in clauses) collectPatternDecls(cl.pattern, out);
        case EReceive(clauses, _): for (cl in clauses) collectPatternDecls(cl.pattern, out);
        case EWith(clauses, _, _): for (cl in clauses) collectPatternDecls(cl.pattern, out);
        case EFor(gens, _, _, _, _): for (g in gens) collectPatternDecls(g.pattern, out);
        case EFn(clauses): for (cl in clauses) for (a in cl.args) collectPatternDecls(a, out);
        case ETry(_, rescueClauses, catchClauses, _, _):
          if (rescueClauses != null) for (rc in rescueClauses) collectPatternDecls(rc.pattern, out);
          if (catchClauses != null) for (cc in catchClauses) collectPatternDecls(cc.pattern, out);
        default:
      }
    });
  }

  static function collectPatternDecls(p: EPattern, out: Map<String,Bool>): Void {
    if (p == null) return;
    switch (p) {
      case PVar(v): out.set(v, true);
      case PAlias(v, pat): out.set(v, true); collectPatternDecls(pat, out);
      case PTuple(items): for (i in items) collectPatternDecls(i, out);
      case PList(items): for (i in items) collectPatternDecls(i, out);
      case PCons(h, t): collectPatternDecls(h, out); collectPatternDecls(t, out);
      case PMap(fields): for (f in fields) collectPatternDecls(f.value, out);
      case PStruct(_, fields): for (f in fields) collectPatternDecls(f.value, out);
      case PBinary(segs): for (s in segs) collectPatternDecls(s.pattern, out);
      case PPin(inner): collectPatternDecls(inner, out);
      default:
    }
  }

  static inline function shouldProcess(name:String): Bool {
    // Limit to LiveView callbacks where helper-binds explode warnings
    return name == "handle_event" || name == "handle_info";
  }

  static function containsRaw(body: ElixirAST): Bool {
    var found = false;
    ASTUtils.walk(body, function(n: ElixirAST) {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case ERaw(_): found = true;
        default:
      }
    });
    return found;
  }
}

#end

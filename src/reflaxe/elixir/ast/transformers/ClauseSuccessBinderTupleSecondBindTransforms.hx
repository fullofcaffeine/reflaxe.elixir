package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseSuccessBinderTupleSecondBindTransforms
 *
 * WHAT
 * - In a case clause shaped `{:ok, binder}`, if the clause body contains a
 *   two-element tuple literal `{:tag, v}` where the second element is a simple
 *   lowercase variable `v` that is undefined in the clause, prefix-bind
 *   `v = binder` to the clause body.
 *
 * WHY
 * - Common, idiomatic pattern: broadcasting or returning `{:ok, value}` and later
 *   using that `value` as the second element of a tagged tuple. If prior passes
 *   did not align/rename the binder, this safely establishes the intended local.
 *
 * HOW
 * - For each ECase clause with pattern `{:ok, PVar(binder)}`:
 *   - Collect declared names (pattern + LHS binds in body)
 *   - Scan body for ETuple of two elements with first a literal and second an
 *     EVar candidate `v` (allow-list: lowercase, not reserved)
 *   - If any candidate v is undefined *and not bound in the outer scope*, prefix
 *     `v = binder` and preserve body

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ClauseSuccessBinderTupleSecondBindTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return transformWithScope(ast, new Map());
  }

  static function transformWithScope(node: ElixirAST, inScope: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;

    return switch (node.def) {
      case EDef(name, args, guards, body):
        var scope = collectPatternVars(args);
        makeASTWithMeta(
          EDef(
            name,
            args,
            guards != null ? transformWithScope(guards, scope) : null,
            transformWithScope(body, scope)
          ),
          node.metadata,
          node.pos
        );

      case EDefp(name, args, guards, body):
        var scope = collectPatternVars(args);
        makeASTWithMeta(
          EDefp(
            name,
            args,
            guards != null ? transformWithScope(guards, scope) : null,
            transformWithScope(body, scope)
          ),
          node.metadata,
          node.pos
        );

      case EFn(clauses):
        makeASTWithMeta(
          EFn(clauses.map(cl -> {
            // Closure scope: args bind locally, free vars come from outer scope.
            var fnScope = cloneScope(inScope);
            for (a in cl.args) collectPatternVarsInto(a, fnScope);
            {
              args: cl.args,
              guard: cl.guard != null ? transformWithScope(cl.guard, fnScope) : null,
              body: transformWithScope(cl.body, fnScope)
            };
          })),
          node.metadata,
          node.pos
        );

      case EBlock(expressions):
        // Sequential scope: binders from earlier statements are in scope for later ones.
        var localScope = cloneScope(inScope);
        var out:Array<ElixirAST> = [];
        for (expr in expressions) {
          var next = transformWithScope(expr, localScope);
          out.push(next);
          bindFromStatement(next, localScope);
        }
        makeASTWithMeta(EBlock(out), node.metadata, node.pos);

      case EDo(expressions):
        var localScope = cloneScope(inScope);
        var out:Array<ElixirAST> = [];
        for (expr in expressions) {
          var next = transformWithScope(expr, localScope);
          out.push(next);
          bindFromStatement(next, localScope);
        }
        makeASTWithMeta(EDo(out), node.metadata, node.pos);

      case ECase(target, clauses):
        var outClauses:Array<ECaseClause> = [];
        for (clause in clauses) {
          var clauseScope = cloneScope(inScope);
          collectPatternVarsInto(clause.pattern, clauseScope);

          var newGuard = clause.guard != null ? transformWithScope(clause.guard, clauseScope) : null;
          var newBody = transformWithScope(clause.body, clauseScope);

          outClauses.push(processClause({ pattern: clause.pattern, guard: newGuard, body: newBody }, inScope));
        }
        makeASTWithMeta(ECase(transformWithScope(target, inScope), outClauses), node.metadata, node.pos);

      default:
        // Recurse into children with the same scope.
        ElixirASTTransformer.transformAST(node, child -> transformWithScope(child, inScope));
    };
  }

  static function processClause(cl: ECaseClause, outerScope: Map<String, Bool>): ECaseClause {
    var okBinder = extractOkBinder(cl.pattern);
    if (okBinder == null) return cl;

    var declared = new Map<String,Bool>();
    collectPatternDecls(cl.pattern, declared);
    collectLhsDeclsInBody(cl.body, declared);

    var candidates = findTupleSecondVars(cl.body);
    var chosen:Null<String> = null;
    for (v in candidates) {
      if (!declared.exists(v) && allow(v) && (outerScope == null || !outerScope.exists(v))) {
        chosen = v;
        break;
      }
    }
    if (chosen == null) return cl;

    var prefix = makeAST(EBinary(Match, makeAST(EVar(chosen)), makeAST(EVar(okBinder))));
    var newBody = switch (cl.body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), cl.body.metadata, cl.body.pos);
      case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), cl.body.metadata, cl.body.pos);
      default: makeASTWithMeta(EBlock([prefix, cl.body]), cl.body.metadata, cl.body.pos);
    };
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }

  static function bindFromStatement(stmt: ElixirAST, scope: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null) return;
    switch (stmt.def) {
      case EMatch(pat, _):
        collectPatternVarsInto(pat, scope);
      case EBinary(Match, left, _):
        collectLhsVars(left, scope);
      default:
    }
  }

  static function collectLhsVars(lhs: ElixirAST, out: Map<String, Bool>): Void {
    if (lhs == null || lhs.def == null) return;
    switch (lhs.def) {
      case EVar(nm) if (nm != null && nm.length > 0):
        out.set(nm, true);
      case EPin(_):
        // pinned vars do not bind
      case ETuple(items) | EList(items):
        for (i in items) collectLhsVars(i, out);
      case EKeywordList(pairs):
        for (p in pairs) collectLhsVars(p.value, out);
      case EMap(pairs2):
        for (p in pairs2) collectLhsVars(p.value, out);
      case EBinary(Match, l, r):
        collectLhsVars(l, out);
        collectLhsVars(r, out);
      default:
    }
  }

  static function cloneScope(m: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (m != null) for (k in m.keys()) out.set(k, true);
    return out;
  }

  static function collectPatternVars(args: Array<EPattern>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (args == null) return out;
    for (p in args) collectPatternVarsInto(p, out);
    return out;
  }

  static function collectPatternVarsInto(p: EPattern, out: Map<String, Bool>): Void {
    if (p == null) return;
    switch (p) {
      case PVar(n) if (n != null && n.length > 0):
        out.set(n, true);
      case PAlias(nm, inner):
        if (nm != null && nm.length > 0) out.set(nm, true);
        collectPatternVarsInto(inner, out);
      case PPin(_):
        // pinned vars do not bind; outer scope must already contain them
      case PTuple(es) | PList(es):
        for (e in es) collectPatternVarsInto(e, out);
      case PCons(h, t):
        collectPatternVarsInto(h, out);
        collectPatternVarsInto(t, out);
      case PMap(kvs):
        for (kv in kvs) collectPatternVarsInto(kv.value, out);
      case PStruct(_, fs):
        for (f in fs) collectPatternVarsInto(f.value, out);
      default:
    }
  }

  static function extractOkBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"): switch (es[1]) { case PVar(n): n; default: null; }
          default: null;
        }
      default: null;
    }
  }
  static function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
  static function collectPatternDecls(p:EPattern, vars:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
      case PCons(h,t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
      case PPin(inner): collectPatternDecls(inner, vars);
      default:
    }
  }
  static function collectLhsDeclsInBody(body:ElixirAST, vars:Map<String,Bool>):Void {
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) { case EMatch(p,_): collectPatternDecls(p, vars); case EBinary(Match, l,_): collectLhs(l, vars); default: }
    });
  }
  static function collectLhs(lhs:ElixirAST, vars:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): vars.set(n,true); case EBinary(Match, l2,_): collectLhs(l2, vars); default: }
  }
  static function findTupleSecondVars(body:ElixirAST): Array<String> {
    var found:Map<String,Bool> = new Map();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      switch (x.def) {
        case ETuple(items) if (items.length == 2):
          switch (items[1].def) { case EVar(v): found.set(v, true); default: }
        default:
      }
    });
    return [for (k in found.keys()) k];
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseErrorVarUnifyTransforms
 *
 * WHAT
 * - Promotes error-binder names in `{:error, _x}` patterns to `{:error, x}` when the
 *   clause body clearly references `x`. Also replaces undefined lower-case refs in the
 *   error clause body with the bound binder when appropriate.
 */
class CaseErrorVarUnifyTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return transformWithScope(ast, new Map());
  }

  /**
   * Walk the AST with a lightweight function-parameter scope.
   *
   * WHY
   * - Case clause bodies share the surrounding function scope in Elixir.
   * - Treating function parameters as "undefined vars" inside clauses can corrupt semantics by
   *   rewriting outer vars to the case binder (regression: enum_index_usage unwrap_or/2).
   */
  static function transformWithScope(node: ElixirAST, inScope: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;

    return switch (node.def) {
      case EDef(name, args, guards, body):
        var paramNames = collectPatternVars(args);
        makeASTWithMeta(
          EDef(
            name,
            args,
            guards != null ? transformWithScope(guards, paramNames) : null,
            transformWithScope(body, paramNames)
          ),
          node.metadata,
          node.pos
        );

      case EDefp(name, args, guards, body):
        var paramNames = collectPatternVars(args);
        makeASTWithMeta(
          EDefp(
            name,
            args,
            guards != null ? transformWithScope(guards, paramNames) : null,
            transformWithScope(body, paramNames)
          ),
          node.metadata,
          node.pos
        );

      case EFn(clauses):
        makeASTWithMeta(
          EFn(clauses.map(cl -> {
            var fnParams = collectPatternVars(cl.args);
            {
              args: cl.args,
              guard: cl.guard != null ? transformWithScope(cl.guard, fnParams) : null,
              body: transformWithScope(cl.body, fnParams)
            };
          })),
          node.metadata,
          node.pos
        );

      case ECase(expr, clauses):
        var newClauses = [];
        for (cl in clauses) {
          var rewritten = {
            pattern: cl.pattern,
            guard: cl.guard != null ? transformWithScope(cl.guard, inScope) : null,
            body: transformWithScope(cl.body, inScope)
          };
          newClauses.push(processClause(rewritten, inScope));
        }
        makeASTWithMeta(ECase(transformWithScope(expr, inScope), newClauses), node.metadata, node.pos);

      default:
        // Recurse into child expressions with the same scope.
        ElixirASTTransformer.transformAST(node, function(child: ElixirAST): ElixirAST {
          return transformWithScope(child, inScope);
        });
    };
  }

  static function processClause(cl: {pattern:EPattern, guard:ElixirAST, body:ElixirAST}, inScope: Map<String, Bool>): {pattern:EPattern, guard:ElixirAST, body:ElixirAST} {
    // Only {:error, PVar(b)}
    var tag = switch (cl.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral(l) : switch (l.def) { case EAtom(a): a; default: null; } default: null; }
      default: null;
    };
    if (tag != "error") return cl;
    var binder:Null<String> = switch (cl.pattern) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    };
    if (binder == null) return cl;
    // Promote _x -> x when body references x
    if (binder.length > 1 && binder.charAt(0) == '_') {
      var cand = binder.substr(1);
      if (bodyUsesName(cl.body, cand)) {
        var newPat = switch (cl.pattern) {
          case PTuple(es2) if (es2.length == 2): PTuple([es2[0], PVar(cand)]);
          default: cl.pattern;
        };
        return { pattern: newPat, guard: cl.guard, body: cl.body };
      }
    }
    // Replace undefined simple vars with the bound binder (when body uses it and no rename needed)
    var used = collectNames(cl.body);
    // Only do replacement when a single undefined lower-case var exists
    var declared = collectDeclared(cl.pattern, cl.body);
    var undef:Array<String> = [];
    for (u in used.keys()) {
      if (!declared.exists(u) && isLower(u) && (inScope == null || !inScope.exists(u))) {
        undef.push(u);
      }
    }
    if (undef.length == 1) {
      var target = binder;
      var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
        return switch (x.def) { case EVar(v) if (v == undef[0]): makeASTWithMeta(EVar(target), x.metadata, x.pos); default: x; }
      });
      return { pattern: cl.pattern, guard: cl.guard, body: newBody };
    }
    return cl;
  }

  static function bodyUsesName(body: ElixirAST, name:String):Bool {
    var used = false;
    ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      switch (n.def) { case EVar(v) if (v == name): used = true; default: }
      return n;
    });
    return used;
  }

  static function collectNames(body: ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){ switch (n.def) { case EVar(v): m.set(v,true); default: }});
    return m;
  }
  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var d = new Map<String,Bool>();
    // pattern binds
    switch (p) {
      case PVar(n): d.set(n,true);
      case PTuple(es): for (e in es) switch (e) { case PVar(n2): d.set(n2,true); default: }
      default:
    }
    // local LHS assigns inside body
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) {
        case EMatch(PVar(nm), _): d.set(nm,true);
        case EBinary(Match, {def: EVar(nm2)}, _): d.set(nm2,true);
        default:
      }
    });
    return d;
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
      case PPin(inner):
        collectPatternVarsInto(inner, out);
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
  static inline function isLower(s:String):Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseUndefinedRefRewriteTransforms
 *
 * WHAT
 * - Within case clauses that bind exactly one payload variable (e.g., {:tag, binder}),
 *   rewrite references to a single undefined local in the body to that binder. Does not
 *   rename the binder itself. Function parameters are treated as defined and never rewritten.
 *
 * WHY
 * - Prevent undefined-variable errors when bodies use meaningful names (todo/id/sort_by)
 *   while the pattern binds a generic name. Keeps transforms generic and shape-based.
 */
class ClauseUndefinedRefRewriteTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var params = collectParamVars(args);
          makeASTWithMeta(EDef(name, args, guards, processBody(body, params)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          var params2 = collectParamVars(args);
          makeASTWithMeta(EDefp(name, args, guards, processBody(body, params2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function processBody(body: ElixirAST, fnParams: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractSingleBinder(cl.pattern);
            if (binder != null) {
              var declared = new Map<String,Bool>();
              // clause-local declarations
              collectPatternVars(cl.pattern, declared);
              collectLhsVarsInBody(cl.body, declared);
              // merge function params
              if (fnParams != null) for (k in fnParams.keys()) declared.set(k, true);
              // gather used
              var used = collectUsedVars(cl.body);
              var undef = [];
              for (u in used.keys()) if (!declared.exists(u) && u != binder && allow(u)) undef.push(u);
              if (undef.length == 1) {
                var targetName = undef[0];
                // Prefer snake_case equivalence when available
                var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(targetName);
                if (snake != null && snake != targetName) {
                  // If snake matches an existing declared local, rewrite to that
                  if (declared.exists(snake)) {
                    var newBodySnake = replaceVar(cl.body, targetName, snake);
                    out.push({ pattern: cl.pattern, guard: cl.guard, body: newBodySnake });
                    continue;
                  }
                  // If snake is exactly the binder, prefer rewriting to binder's canonical snake case
                  if (snake == binder) {
                    var newBodyBinder = replaceVar(cl.body, targetName, binder);
                    out.push({ pattern: cl.pattern, guard: cl.guard, body: newBodyBinder });
                    continue;
                  }
                }
                // Default behavior: rewrite undefined to the binder
                var newBody = replaceVar(cl.body, targetName, binder);
                out.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                continue;
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(target, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "live_socket" || name == "liveSocket") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }

  static function replaceVar(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(e:ElixirAST): ElixirAST {
      return switch (e.def) { case EVar(v) if (v == from): makeASTWithMeta(EVar(to), e.metadata, e.pos); default: e; };
    });
  }

  static function collectParamVars(args: Array<EPattern>): Map<String,Bool> {
    var out = new Map<String,Bool>();
    if (args == null) return out;
    for (a in args) collectPatternVars(a, out);
    return out;
  }

  static function extractSingleBinder(p:EPattern): Null<String> {
    return switch (p) { case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; } default: null; }
  }

  static function collectUsedVars(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ElixirASTTransformer.transformNode(ast, function(e: ElixirAST): ElixirAST {
      switch (e.def) { case EVar(v): names.set(v, true); default: }
      return e;
    });
    return names;
  }

  static function collectLhsVarsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
    reflaxe.elixir.ast.ASTUtils.walk(body, function(e: ElixirAST) {
      if (e == null || e.def == null) return;
      switch (e.def) {
        case EMatch(p, _): collectPatternVars(p, vars);
        case EBinary(Match, l, _): collectLhs(l, vars);
        case ECase(_, cs): for (c in cs) collectPatternVars(c.pattern, vars);
        case EFn(clauses):
          for (cl in clauses) {
            if (cl.args != null) for (a in cl.args) collectPatternVars(a, vars);
          }
        default:
      }
    });
  }

  static function collectPatternVars(p: EPattern, vars: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternVars(e, vars);
      case PCons(h,t): collectPatternVars(h, vars); collectPatternVars(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternVars(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternVars(f.value, vars);
      case PPin(inner): collectPatternVars(inner, vars);
      default:
    }
  }

  static function collectLhs(l: ElixirAST, vars: Map<String,Bool>): Void {
    switch (l.def) { case EVar(n): vars.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, vars); default: }
  }
}

#end

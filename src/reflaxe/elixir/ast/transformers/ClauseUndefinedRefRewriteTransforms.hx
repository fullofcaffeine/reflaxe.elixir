package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

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
    return rewriteNode(ast, new Map<String, Bool>());
  }

  static function cloneEnv(env: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (env != null) for (k in env.keys()) out.set(k, true);
    return out;
  }

  static function rewriteNode(node: ElixirAST, env: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;

    return switch (node.def) {
      case EDef(name, args, guards, body):
        var fnEnv = cloneEnv(env);
        for (a in args) collectPatternVars(a, fnEnv);
        makeASTWithMeta(EDef(name, args, guards, rewriteNode(body, fnEnv)), node.metadata, node.pos);

      case EDefp(name, args, guards, body):
        var functionEnv = cloneEnv(env);
        for (a in args) collectPatternVars(a, functionEnv);
        makeASTWithMeta(EDefp(name, args, guards, rewriteNode(body, functionEnv)), node.metadata, node.pos);

      case EBlock(stmts):
        var blockEnv = cloneEnv(env);
        var newStmts: Array<ElixirAST> = [];
        for (statement in stmts) {
          var rewrittenStatement = rewriteNode(statement, blockEnv);
          newStmts.push(rewrittenStatement);
          collectDeclaredFromStatement(rewrittenStatement, blockEnv);
        }
        makeASTWithMeta(EBlock(newStmts), node.metadata, node.pos);

      case EDo(stmts):
        var doEnv = cloneEnv(env);
        var newStmts: Array<ElixirAST> = [];
        for (statement in stmts) {
          var rewrittenStatement = rewriteNode(statement, doEnv);
          newStmts.push(rewrittenStatement);
          collectDeclaredFromStatement(rewrittenStatement, doEnv);
        }
        makeASTWithMeta(EDo(newStmts), node.metadata, node.pos);

      case ECase(target, clauses):
        var newTarget = rewriteNode(target, env);
        var out: Array<ECaseClause> = [];
        for (cl in clauses) {
          var clauseEnv = cloneEnv(env);
          collectPatternVars(cl.pattern, clauseEnv);

          var newGuard = cl.guard != null ? rewriteNode(cl.guard, clauseEnv) : null;
          var newBody = rewriteNode(cl.body, clauseEnv);

          var binder = extractSingleBinder(cl.pattern);
          if (binder != null) {
            // clause-local declarations = outer scope + pattern vars + LHS binds inside the clause body
            var declared = cloneEnv(clauseEnv);
            collectLhsVarsInBody(newBody, declared);

            var used = OptimizedVarUseAnalyzer.referencedVarsExact(newBody);
            var undef: Array<String> = [];
            for (u in used.keys()) if (!declared.exists(u) && u != binder && allow(u)) undef.push(u);

            if (undef.length == 1) {
              var targetName = undef[0];
              // Prefer snake_case equivalence when available
              var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(targetName);
              if (snake != null && snake != targetName) {
                // If snake matches an existing declared local, rewrite to that
                if (declared.exists(snake)) {
                  out.push({ pattern: cl.pattern, guard: newGuard, body: replaceVar(newBody, targetName, snake) });
                  continue;
                }
                // If snake is exactly the binder, prefer rewriting to binder
                if (snake == binder) {
                  out.push({ pattern: cl.pattern, guard: newGuard, body: replaceVar(newBody, targetName, binder) });
                  continue;
                }
              }
              // Default behavior: rewrite undefined to the binder
              out.push({ pattern: cl.pattern, guard: newGuard, body: replaceVar(newBody, targetName, binder) });
              continue;
            }
          }

          out.push({ pattern: cl.pattern, guard: newGuard, body: newBody });
        }
        makeASTWithMeta(ECase(newTarget, out), node.metadata, node.pos);

      default:
        ElixirASTTransformer.transformAST(node, function(child: ElixirAST): ElixirAST {
          return rewriteNode(child, env);
        });
    };
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

  static function extractSingleBinder(p:EPattern): Null<String> {
    return switch (p) { case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; } default: null; }
  }

  static function collectDeclaredFromStatement(stmt: ElixirAST, vars: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null || vars == null) return;
    switch (stmt.def) {
      case EMatch(p, _): collectPatternVars(p, vars);
      case EBinary(Match, left, _): collectLhs(left, vars);
      case ECase(_, cs): for (c in cs) collectPatternVars(c.pattern, vars);
      default:
    }
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
    switch (l.def) { case EVar(n): vars.set(n, true); case EBinary(Match, nestedLeft, _): collectLhs(nestedLeft, vars); default: }
  }
}

#end

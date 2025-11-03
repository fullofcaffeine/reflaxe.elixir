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
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push(processClause(cl));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function processClause(cl: {pattern:EPattern, guard:ElixirAST, body:ElixirAST}): {pattern:EPattern, guard:ElixirAST, body:ElixirAST} {
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
    for (u in used.keys()) if (!declared.exists(u) && isLower(u)) undef.push(u);
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
  static inline function isLower(s:String):Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }
}

#end


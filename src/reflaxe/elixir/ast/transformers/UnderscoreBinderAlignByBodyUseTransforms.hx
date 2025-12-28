package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * UnderscoreBinderAlignByBodyUseTransforms
 *
 * WHAT
 * - For any case clause shaped as `{:tag, _binder}` (binder starts with underscore),
 *   if the clause body uses exactly one undefined lowercase variable, rename the binder
 *   to that variable and keep the body unchanged. Scope-aware and generic (no app ties).
 *
 * WHY
 * - Builders may generate temporary underscored binders (e.g., `_g3`) for success/data
 *   payloads. When the clause body clearly intends a name (e.g., `updated_todo`), this
 *   pass promotes the binder to that name for correctness and readability.
 *
 * HOW
 * - Walk EDef/EDefp bodies, visiting ECase clauses. For each clause with PTuple/2 and
 *   second element PVar(b) where b starts with `_`:
 *   - Compute declared names (pattern binders + LHS inside body) and merge function params.
 *   - Collect used lowercase names in the clause body.
 *   - Let `undef = used \\ declared \\ {b}` excluding env names (socket/live_socket).
 *   - If `undef.length == 1`, rename binder to `undef[0]` and return updated clause.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnderscoreBinderAlignByBodyUseTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var fnDecl = collectFunctionDefinedVars(args, body);
          var nb = process(body, fnDecl);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          var fnDecl2 = collectFunctionDefinedVars(args, body);
          var nb2 = process(body, fnDecl2);
          makeASTWithMeta(EDefp(name, args, guards, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function process(body: ElixirAST, fnDeclared: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractSecondBinder(cl.pattern);
            if (binder != null && isUnderscored(binder)) {
              var base = binder.substr(1);
              var declared = new Map<String,Bool>();
              collectPatternDecls(cl.pattern, declared);
              collectLhsDeclsInBody(cl.body, declared);
              if (fnDeclared != null) for (k in fnDeclared.keys()) declared.set(k, true);
              var used = collectUsedLowerNames(cl.body);
              // Prefer the binder's base name when it is actually used in the body, regardless
              // of how many other locals appear. This avoids false negatives that leave the
              // pattern underscored and produce undefined-variable errors downstream.
              if (allow(base) && used.exists(base) && !declared.exists(base)) {
                var newPat = rewriteSecondBinder(cl.pattern, base);
                if (newPat != null) { out.push({ pattern: newPat, guard: cl.guard, body: cl.body }); continue; }
              }
              // Fallback to original heuristic: single undefined lower-case var
              var undef:Array<String> = [];
              for (u in used.keys()) if (!declared.exists(u) && allow(u)) undef.push(u);
              if (undef.length == 1) {
                var newPat2 = rewriteSecondBinder(cl.pattern, undef[0]);
                if (newPat2 != null) { out.push({ pattern: newPat2, guard: cl.guard, body: cl.body }); continue; }
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

  static inline function isUnderscored(name:String):Bool {
    return name != null && name.length > 1 && name.charAt(0) == '_';
  }
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "live_socket" || name == "liveSocket") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }
  static function extractSecondBinder(p:EPattern):Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }
  static function rewriteSecondBinder(p:EPattern, newName:String):Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)]); default: null; }
      default: null;
    }
  }
  static function collectFunctionDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
    var vars = new Map<String, Bool>();
    for (a in args) collectPatternDecls(a, vars);
    ASTUtils.walk(body, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EMatch(p, _): collectPatternDecls(p, vars);
        case EBinary(Match, l, _): collectLhsDecls(l, vars);
        default:
      }
    });
    return vars;
  }
  static function collectPatternDecls(p: EPattern, vars: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): if (n != null && n.length > 0) vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
      case PCons(h, t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
      case PPin(inner): collectPatternDecls(inner, vars);
      default:
    }
  }
  static function collectLhsDeclsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
    ASTUtils.walk(body, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EMatch(p, _): collectPatternDecls(p, vars);
        case EBinary(Match, l, _): collectLhsDecls(l, vars);
        case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, vars);
        default:
      }
    });
  }
  static function collectLhsDecls(lhs: ElixirAST, vars: Map<String,Bool>): Void {
    switch (lhs.def) {
      case EVar(n): vars.set(n, true);
      case EBinary(Match, l2, r2): collectLhsDecls(l2, vars); collectLhsDecls(r2, vars);
      default:
    }
  }
  static function collectUsedLowerNames(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ASTUtils.walk(ast, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) { case EVar(v): var c = v.charAt(0); if (c.toLowerCase() == c) names.set(v, true); default: }
    });
    return names;
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CaseBinderAlignFinalTransforms
 *
 * WHAT
 * - Absolute-last safety net that aligns the payload binder in `{:tag, binder}`
 *   to the clause's sole undefined local used in the clause body.
 *
 * WHY
 * - Earlier passes may underscore or rename binders; when the body clearly uses a
 *   single undefined variable (todo/id/message), ensure the pattern matches it to
 *   prevent undefined-variable errors. Generic and shape-based.
 *
 * HOW
 * - For each ECase clause with `{:atom, PVar(binder)}`:
 *   - Collect declared names (pattern + LHS matches inside the clause body)
 *   - Collect used simple vars in the body
 *   - If exactly one undefined lower-case name U exists and U != binder,
 *     rename the binder to U and rewrite body occurrences of `binder` to `U` (in case it’s referenced).
 */
class CaseBinderAlignFinalTransforms {
  static function prefer(names:Array<String>): Null<String> {
    if (names == null || names.length == 0) return null;
    var order = ["todo", "id", "message", "params", "reason"];
    for (p in order) for (n in names) if (n == p) return n;
    return null;
  }
  public static function pass(ast: ElixirAST): ElixirAST {
    return rewriteNode(ast, new Map<String, Bool>());
  }

  static function cloneNameSet(src: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (src != null) for (k in src.keys()) out.set(k, true);
    return out;
  }

  static function rewriteNode(node: ElixirAST, env: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;
    return switch (node.def) {
      case EDef(name, args, guards, body):
        var defEnv = cloneNameSet(env);
        for (arg in args) collectPatternBinders(arg, defEnv);
        var nextBody = rewriteNode(body, defEnv);
        makeASTWithMeta(EDef(name, args, guards, nextBody), node.metadata, node.pos);

      case EDefp(name, args, guards, body):
        var defpEnv = cloneNameSet(env);
        for (arg in args) collectPatternBinders(arg, defpEnv);
        var nextBody = rewriteNode(body, defpEnv);
        makeASTWithMeta(EDefp(name, args, guards, nextBody), node.metadata, node.pos);

      case EFn(clauses):
        var nextClauses = [];
        for (clause in clauses) {
          var clauseEnv = cloneNameSet(env);
          for (arg in clause.args) collectPatternBinders(arg, clauseEnv);
          var nextGuard = clause.guard == null ? null : rewriteNode(clause.guard, clauseEnv);
          var nextBody = rewriteNode(clause.body, clauseEnv);
          nextClauses.push({ args: clause.args, guard: nextGuard, body: nextBody });
        }
        makeASTWithMeta(EFn(nextClauses), node.metadata, node.pos);

      case ECase(target, clauses):
        var nextTarget = rewriteNode(target, env);
        var outClauses = [];
        for (cl in clauses) {
          var clauseEnv = cloneNameSet(env);
          collectPatternBinders(cl.pattern, clauseEnv);

          var binder = extractTagPayloadBinder(cl.pattern);
          var nextGuard = cl.guard == null ? null : rewriteNode(cl.guard, clauseEnv);
          var nextBody = rewriteNode(cl.body, clauseEnv);

          if (binder != null) {
            var declared = collectDeclaredNames(cl.pattern, nextBody, clauseEnv);
            var used = collectUsedLowerVars(nextBody);

            var undef:Array<String> = [];
            for (u in used) if (!declared.exists(u) && u != binder) undef.push(u);

            if (undef.length == 0) {
              var ex = new StringMap<Bool>();
              ex.set(binder, true);
              for (k in declared.keys()) ex.set(k, true);
              var alt = findFirstMeaningfulVar(nextBody, ex);
              if (alt != null) undef.push(alt);
            }

            if (undef.length > 1) {
              var prefName = prefer(undef);
              if (prefName != null) undef = [prefName];
            }

            if (undef.length == 1) {
              var newName = undef[0];
              var newPat = rewriteTagPayloadBinder(cl.pattern, newName);
              if (newPat != null) {
                var renamedBody = replaceVar(nextBody, binder, newName);
                var renamedGuard = nextGuard == null ? null : replaceVar(nextGuard, binder, newName);
                outClauses.push({ pattern: newPat, guard: renamedGuard, body: renamedBody });
                continue;
              }
            }
          }

          outClauses.push({ pattern: cl.pattern, guard: nextGuard, body: nextBody });
        }
        makeASTWithMeta(ECase(nextTarget, outClauses), node.metadata, node.pos);

      case EBlock(stmts):
        var blockScope = cloneNameSet(env);
        var nextStatements = [];
        for (statement in stmts) {
          var nextStatement = rewriteNode(statement, blockScope);
          nextStatements.push(nextStatement);
          collectDeclaredFromStatement(nextStatement, blockScope);
        }
        makeASTWithMeta(EBlock(nextStatements), node.metadata, node.pos);

      case EDo(statements):
        var doScope = cloneNameSet(env);
        var nextStatements = [];
        for (statement in statements) {
          var nextStatement = rewriteNode(statement, doScope);
          nextStatements.push(nextStatement);
          collectDeclaredFromStatement(nextStatement, doScope);
        }
        makeASTWithMeta(EDo(nextStatements), node.metadata, node.pos);

      default:
        ElixirASTTransformer.transformAST(node, function(child: ElixirAST): ElixirAST {
          return rewriteNode(child, env);
        });
    };
  }

  static function extractTagPayloadBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral(l):
            switch (es[1]) { case PVar(n): n; default: null; }
          default: null;
        }
      default: null;
    }
  }

  static function rewriteTagPayloadBinder(p:EPattern, newName:String): Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral(_): switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)]); default: null; } default: null; }
      default: null;
    }
  }

  static function collectDeclaredNames(p:EPattern, body: ElixirAST, baseEnv: Map<String, Bool>): Map<String,Bool> {
    var m = cloneNameSet(baseEnv);
    function pat(pt:EPattern):Void {
      switch (pt) {
        case PVar(n): m.set(n, true);
        case PTuple(es) | PList(es): for (e in es) pat(e);
        case PCons(h,t): pat(h); pat(t);
        case PMap(kvs): for (kv in kvs) pat(kv.value);
        case PStruct(_, fs): for (f in fs) pat(f.value);
        case PPin(inner): pat(inner);
        default:
      }
    }
    pat(p);
    // Body LHS
    ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
      return n;
    });
    return m;
  }

  static function collectPatternBinders(p: EPattern, out: Map<String, Bool>): Void {
    if (p == null || out == null) return;
    switch (p) {
      case PVar(n) if (n != null && n.length > 0):
        out.set(n, true);
      case PTuple(es) | PList(es):
        for (e in es) collectPatternBinders(e, out);
      case PCons(h, t):
        collectPatternBinders(h, out);
        collectPatternBinders(t, out);
      case PMap(kvs):
        for (kv in kvs) collectPatternBinders(kv.value, out);
      case PStruct(_, fs):
        for (f in fs) collectPatternBinders(f.value, out);
      case PPin(inner):
        collectPatternBinders(inner, out);
      case PAlias(nm, inner):
        if (nm != null && nm.length > 0) out.set(nm, true);
        collectPatternBinders(inner, out);
      case PBinary(segs):
        for (s in segs) collectPatternBinders(s.pattern, out);
      default:
    }
  }

  static function collectDeclaredFromStatement(stmt: ElixirAST, out: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null || out == null) return;
    switch (stmt.def) {
      case EMatch(pat, _):
        collectPatternBinders(pat, out);
      case EBinary(Match, {def: EVar(lhs)}, _):
        if (lhs != null && lhs.length > 0) out.set(lhs, true);
      default:
    }
  }

  static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
    var names = new Map<String,Bool>();
    // Use builder-provided metadata when present
    var arr = ast.metadata.usedLocalsFromTyped;
    if (arr != null) {
      for (n in arr) if (n != null && n.length > 0 && isLower(n)) names.set(n, true);
    }

    ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      switch (n.def) {
        case EVar(v): if (isLower(v)) names.set(v,true);
        case EString(s):
          if (s != null && s.indexOf("#{") != -1) {
            var block = new EReg("\\#\\{([^}]*)\\}", "g");
            var pos = 0;
            while (block.matchSub(s, pos)) {
              var inner = block.matched(1);
              var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
              var tpos = 0;
              while (tok.matchSub(inner, tpos)) {
                var id = tok.matched(0);
                if (isLower(id)) names.set(id, true);
                tpos = tok.matchedPos().pos + tok.matchedPos().len;
              }
              pos = block.matchedPos().pos + block.matchedPos().len;
            }
          }
        default:
      }
      return n;
    });
    return [for (k in names.keys()) k];
  }

  static function findFirstMeaningfulVar(ast: ElixirAST, exclude:StringMap<Bool>): Null<String> {
    var pick:Null<String> = null;
    ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      if (pick != null || n == null || n.def == null) return n;
      switch (n.def) {
        case EVar(v):
          if (isLower(v) && !exclude.exists(v)) pick = v;
        default:
      }
      return n;
    });
    return pick;
  }

  static inline function isLower(s:String):Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }

  static function replaceVar(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) { case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos); default: n; };
    });
  }
}

#end

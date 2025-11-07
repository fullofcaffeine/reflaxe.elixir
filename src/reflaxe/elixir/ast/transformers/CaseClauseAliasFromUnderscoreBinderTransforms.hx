package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * CaseClauseAliasFromUnderscoreBinderTransforms
 *
 * WHAT
 * - Inside ECase clauses, when the body references a simple lower-case local name `u`
 *   that is undefined in the clause and the pattern binds the underscored variant
 *   `_u`, prefix-bind `u = _u` at the top of the clause body.
 *
 * WHY
 * - Binder-rename passes can be risky and app-coupled. This pass provides a
 *   clause‑local aliasing strategy that keeps pattern binders intact while making
 *   clause bodies compile and read cleanly. It is strictly shape‑based and avoids
 *   name heuristics beyond the explicit `_u` → `u` relationship.
 *
 * HOW
 * - For each ECase clause:
 *   1) Collect declared names from the pattern variables and any LHS declarations
 *      within the body (match patterns and simple `lhs = ...`).
 *   2) Collect used lower‑case names in the body (EVar + lightweight interpolation scan).
 *   3) For each undefined name `u` where the pattern contains `_u`, inject `u = _u`
 *      as the first statement in the clause body (EBlock/EDo wrapper if needed).
 * - Skips reserved env names (socket/params/event) and self‑assignments.
 *
 * EXAMPLES
 * Haxe:
 *   switch status {
 *     case Working(task): 'Task: $task';
 *   }
 * Elixir (pattern underscored by hygiene):
 *   case status do
 *     {:working, _task} ->
 *       task = _task
 *       "Task: #{task}"
 *   end
 */
class CaseClauseAliasFromUnderscoreBinderTransforms {
  public static function aliasPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(aliasInClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function aliasInClause(cl: ECaseClause): ECaseClause {
    // Skip aliasing for any tagged tuple {:tag, ...} (any arity): binder-rename passes handle these idiomatically.
    var isTaggedTuple = switch (cl.pattern) {
      case PTuple(es): switch (es[0]) { case PLiteral(_): true; default: false; }
      default: false;
    };
    if (isTaggedTuple) return cl;
    var declared = collectDeclared(cl.pattern, cl.body);
    var used = collectUsedLowerNames(cl.body);
    var patHasUnderscored: Map<String,Bool> = collectUnderscoredBinders(cl.pattern);

    #if (sys && !no_traces)
    // Debug snapshot for this clause
    var declArr = [for (k in declared.keys()) k].join(',');
    var usedArr = [for (k in used.keys()) k].join(',');
    var patArr = [for (k in patHasUnderscored.keys()) k].join(',');
    Sys.println('[CaseAliasUnderscore] decl={' + declArr + '} used={' + usedArr + '} patU={' + patArr + '}');
    #end

    // Compute alias candidates: primary path uses explicit `used` set.
    var aliases:Array<{u:String, from:String}> = [];
    for (u in used.keys()) {
      if (!allow(u)) continue;
      if (declared.exists(u)) continue;
      var src = '_' + u;
      if (patHasUnderscored.exists(src)) aliases.push({u: u, from: src});
    }

    // Fallback: if nothing found, inspect printed body to detect plain identifier occurrence
    if (aliases.length == 0 && Lambda.count(patHasUnderscored) > 0) {
      try {
        var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(cl.body, 0);
        for (key in patHasUnderscored.keys()) {
          var base = key.substr(1);
          if (!allow(base)) continue;
          if (declared.exists(base)) continue;
          // Word-boundary style search without heavy regex deps
          var idx = printed.indexOf(base);
          if (idx != -1) {
            // Basic boundary checks
            var ok = true;
            if (idx > 0) {
              var prev = printed.charAt(idx - 1);
              if (isIdent(prev)) ok = false;
            }
            var endIdx = idx + base.length;
            if (endIdx < printed.length) {
              var next = printed.charAt(endIdx);
              if (isIdent(next)) ok = false;
            }
            if (ok) aliases.push({u: base, from: key});
          }
        }
      } catch (e:Dynamic) {}
    }

    if (aliases.length == 0) return cl;

    // Build alias statements, skipping self-assignments and duplicates
    var prefix:Array<ElixirAST> = [];
    var seen = new Map<String,Bool>();
    for (a in aliases) {
      if (seen.exists(a.u)) continue; seen.set(a.u, true);
      if (a.u == a.from) continue;
      prefix.push(makeAST(EBinary(Match, makeAST(EVar(a.u)), makeAST(EVar(a.from)))));
    }
    if (prefix.length == 0) return cl;

    #if (sys && !no_traces)
    for (a in aliases) Sys.println('[CaseAliasUnderscore] prefix ' + a.u + ' = ' + a.from);
    #end
    var newBody = switch (cl.body.def) {
      case EBlock(sts):
        makeASTWithMeta(EBlock(prefix.concat(sts)), cl.body.metadata, cl.body.pos);
      case EDo(sts2):
        makeASTWithMeta(EDo(prefix.concat(sts2)), cl.body.metadata, cl.body.pos);
      default:
        makeASTWithMeta(EBlock(prefix.concat([cl.body])), cl.body.metadata, cl.body.pos);
    };
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }

  static inline function isIdent(ch: String): Bool {
    if (ch == null || ch.length == 0) return false;
    var c = ch.charCodeAt(0);
    return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
  }

  static function collectUnderscoredBinders(p:EPattern): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function walk(px:EPattern):Void {
      switch (px) {
        case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
          m.set(n, true);
        case PTuple(es): for (e in es) walk(e);
        case PList(es): for (e in es) walk(e);
        case PCons(h, t): walk(h); walk(t);
        case PMap(kvs): for (kv in kvs) walk(kv.value);
        case PStruct(_, fs): for (f in fs) walk(f.value);
        case PPin(inner): walk(inner);
        default:
      }
    }
    walk(p);
    return m;
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function pat(px:EPattern):Void {
      switch (px) {
        case PVar(n) if (n != null && n.length > 0): m.set(n, true);
        case PTuple(es) | PList(es): for (e in es) pat(e);
        case PCons(h,t): pat(h); pat(t);
        case PMap(kvs): for (kv in kvs) pat(kv.value);
        case PStruct(_, fs): for (f in fs) pat(f.value);
        case PPin(inner): pat(inner);
        default:
      }
    }
    pat(p);
    ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
    });
    return m;
  }

  static function collectUsedLowerNames(body: ElixirAST): Map<String,Bool> {
    var used = new Map<String,Bool>();
    // Collect from AST vars
    ASTUtils.walk(body, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EVar(v): if (looksLower(v)) used.set(v, true);
        case EString(s): markInterpolations(s, used);
        case ERaw(code): markInterpolations(code, used);
        default:
      }
    });
    return used;
  }

  static inline function looksLower(name:String): Bool {
    if (name == null || name.length == 0) return false;
    var c = name.charAt(0);
    return c == c.toLowerCase();
  }

  static function markInterpolations(s:String, used:Map<String,Bool>):Void {
    if (s == null) return;
    var reBlock = new EReg("\\#\\{([^}]*)\\}", "g");
    var pos = 0;
    while (reBlock.matchSub(s, pos)) {
      var inner = reBlock.matched(1);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var tpos = 0;
      while (tok.matchSub(inner, tpos)) {
        var id = tok.matched(0);
        if (looksLower(id)) used.set(id, true);
        tpos = tok.matchedPos().pos + tok.matchedPos().len;
      }
      pos = reBlock.matchedPos().pos + reBlock.matchedPos().len;
    }
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    return true;
  }
}

#end

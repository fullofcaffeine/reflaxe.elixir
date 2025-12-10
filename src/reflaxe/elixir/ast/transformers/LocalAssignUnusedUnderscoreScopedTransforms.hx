package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnusedUnderscoreScopedTransforms
 *
 * WHAT
 * - Underscore assignment binders that are not referenced later in the same
 *   block, but only within safe scopes: any def/defp except `mount`.
 *
 * WHY
 * - Silences unused local warnings in controllers, LiveView handle_event
 *   bodies, and render helpers without touching mount/3 where rebinding
 *   `socket` may be intentionally propagated.
 *
 * HOW
 * - For each EDef/EDefp whose name != "mount", rewrite EBlock/EDo children so
 *   that `name = expr` becomes `_name = expr` when `name` is not referenced in
 *   any subsequent statement within the same block.
 */
  class LocalAssignUnusedUnderscoreScopedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      // Gate (relaxed for WAE): when inside LiveView modules, only allow on
      // render_* helpers and handle_event/3 to avoid false positives.
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            var isRender = StringTools.startsWith(name, "render_");
            var isHandleEvent = name == "handle_event" && args != null && args.length == 3;
            var isHandleInfo = name == "handle_info" && args != null && args.length == 2;
            if (!isRender && !isHandleEvent && !isHandleInfo) return n;
          }
          var newBody = rewriteBlocks(body);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (name2 != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            var isRender2 = StringTools.startsWith(name2, "render_");
            var isHandleEvent2 = name2 == "handle_event" && args2 != null && args2.length == 3;
            var isHandleInfo2 = name2 == "handle_info" && args2 != null && args2.length == 2;
            if (!isRender2 && !isHandleEvent2 && !isHandleInfo2) return n;
          }
          var newBody2 = rewriteBlocks(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, newBody2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBlocks(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(rewrite(stmts)), x.metadata, x.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(rewrite(stmts2)), x.metadata, x.pos);
        case ECase(expr, clauses):
          makeASTWithMeta(ECase(expr, rewriteClauses(clauses)), x.metadata, x.pos);
        case EFn(clauses):
          var newClauses = [];
          for (c in clauses) {
            var nb = rewriteBlocks(c.body);
            newClauses.push({args: c.args, guard: c.guard, body: nb});
          }
          makeASTWithMeta(EFn(newClauses), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var usedLater = new Map<String,Bool>();

    // Reverse scan so we see future uses without quadratic lookahead
    var idx = stmts.length - 1;
    while (idx >= 0) {
      var s = stmts[idx];
      var rewritten = s;
      var nextStmt:ElixirAST = (idx + 1 < stmts.length) ? stmts[idx + 1] : null;
      switch (s.def) {
        case EMatch(PVar(b), rhs):
          if (skipAliasToCaseScrutinee(rhs, nextStmt)) {
            idx--;
            continue;
          }
          if (shouldRewriteBinder(b, usedLater, rhs)) {
            rewritten = makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
          }
        case EBinary(Match, {def: EVar(b2)}, rhs2):
          if (skipAliasToCaseScrutinee(rhs2, nextStmt)) {
            idx--;
            continue;
          }
          if (shouldRewriteBinder(b2, usedLater, rhs2)) {
            rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
          } else {
            // also allow aligning Map.get(params, "key") → key when key used later
            switch (rhs2.def) {
              case ERemoteCall({def: EVar("Map")}, "get", ra) if (ra != null && ra.length == 2):
                switch (ra[1].def) {
                  case EString(key) if (usedLater.exists(key) && !usedLater.exists(b2)):
                    rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs2), s.metadata, s.pos);
                  default:
                }
              default:
            }
          }
        default:
      }

      collectUsedVars(rewritten, usedLater);
      out.unshift(rewritten);
      idx--;
    }
    return out;
  }

  static inline function shouldRewriteBinder(name:String, usedLater:Map<String,Bool>, rhs:ElixirAST):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "children") return false;
    if (name.charAt(0) == '_') return false;
    if (usedLater.exists(name)) return false;
    return isEphemeralRhs(rhs) || (name == "g" && isCase(rhs)) || isSimpleVar(rhs);
  }

  static function isCase(rhs: ElixirAST): Bool {
    return switch (rhs.def) {
      case ECase(_, _): true;
      default: false;
    }
  }

  static function collectUsedVars(node: ElixirAST, out: Map<String,Bool>): Void {
    reflaxe.elixir.ast.ASTUtils.walk(node, function(x:ElixirAST){
      switch (x.def) {
        case EVar(v): out.set(v, true);
        default:
      }
    });
  }

  static function isEphemeralRhs(rhs: ElixirAST): Bool {
    return switch (rhs.def) {
      case ERemoteCall({def: EVar("Map")}, fnName, args) if (fnName == "get" && args != null && args.length == 2):
        // Ephemeral when key is a string and not a structural extraction
        switch (args[1].def) {
          case EString(_): true;
          default: isNuisanceKey(args[1]);
        }
      // Do not treat list/map literals as ephemeral; they may be used later (e.g., permitted fields)
      default: false;
    }
  }

  static function isSimpleVar(rhs: ElixirAST): Bool {
    return switch (rhs.def) {
      case EVar(_): true;
      default: false;
    }
  }

  static function skipAliasToCaseScrutinee(rhs:ElixirAST, nextStmt:ElixirAST):Bool {
    if (nextStmt == null || nextStmt.def == null) return false;
    var rhsVar:Null<String> = switch (rhs.def) { case EVar(v): v; default: null; };
    if (rhsVar == null) return false;
    return switch (nextStmt.def) {
      case ECase(expr, _):
        switch (expr.def) { case EVar(v2) if (v2 == rhsVar): true; default: false; }
      default: false;
    }
  }

  static function rewriteClauses(cs:Array<ECaseClause>):Array<ECaseClause> {
    var out:Array<ECaseClause> = [];
    for (c in cs) {
      var used = new Map<String,Bool>();
      var newBody = rewriteBlocks(c.body);
      if (newBody != null) collectUsedVars(newBody, used);
      if (c.guard != null) collectUsedVars(c.guard, used);
      var pat = underscoreUnusedInPattern(c.pattern, used);
      out.push({ pattern: pat, guard: c.guard, body: newBody });
    }
    return out;
  }

  static function underscoreUnusedInPattern(p:EPattern, used:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n) if (!used.exists(n) && n != null && n.length > 0 && n.charAt(0) != '_'): PVar('_' + n);
      case PTuple(items):
        PTuple([for (i in items) underscoreUnusedInPattern(i, used)]);
      case PList(items):
        PList([for (i in items) underscoreUnusedInPattern(i, used)]);
      case PCons(h, t):
        PCons(underscoreUnusedInPattern(h, used), underscoreUnusedInPattern(t, used));
      case PMap(fs):
        PMap([for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PStruct(mod, fs):
        PStruct(mod, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PBinary(segs):
        PBinary([for (s in segs) { pattern: underscoreUnusedInPattern(s.pattern, used), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner):
        PPin(underscoreUnusedInPattern(inner, used));
      default:
        p;
    }
  }

  static function isNuisanceKey(arg: ElixirAST): Bool {
    return switch (arg.def) {
      case EString(s) if (s == "to_string" || s == "fn" || s == "end" || s == "sort_by"): true;
      default: false;
    }
  }
}

#end

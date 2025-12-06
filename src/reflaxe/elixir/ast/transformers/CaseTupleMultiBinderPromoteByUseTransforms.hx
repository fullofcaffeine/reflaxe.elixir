package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseTupleMultiBinderPromoteByUseTransforms
 *
 * WHAT
 * - In case clause tuple patterns like {:tag, _a, _b, ...}, promote any
 *   underscore-prefixed binder to its base name (a, b, ...) when the base
 *   name is referenced in the clause body (including inside string/ERaw
 *   interpolations: #{...}). Applies to any tuple arity >= 2 and leaves
 *   non-underscore binders intact.
 *
 * WHY
 * - Snapshot suites rely on idiomatic binders (result/duration) instead of
 *   underscored variants when the values are actually used. Later “underscore
 *   unused” passes must not trigger for used binders.
 *
 * HOW
 * - For each ECase clause, collect body-used names (AST vars + interpolation
 *   identifiers). For tuple patterns (PTuple), scan each PVar("_name") and if
 *   `name` is in used set, rewrite to PVar("name"). Also normalizes nested
 *   tuple/list/map/struct binders recursively.
 */
class CaseTupleMultiBinderPromoteByUseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(promoteInClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function promoteInClause(cl: ECaseClause): ECaseClause {
    var used = collectUsedNames(cl.body);
    if (cl.guard != null) mergeInto(used, collectUsedNames(cl.guard));
    var promoted = promoteInPattern(cl.pattern, used);
    // Fallback: if nothing changed and pattern has underscored binders, promote
    // when the clause body text contains the base name anywhere (best-effort),
    // guarding against app coupling by deriving bases only from the pattern.
    if (promoted == cl.pattern) {
      var bases = collectUnderscoredBases(cl.pattern);
      if (bases.length > 0 && (bodyContainsAny(cl.body, bases) || (cl.guard != null && bodyContainsAny(cl.guard, bases)))) {
        var used2 = new Map<String,Bool>();
        for (b in bases) used2.set(b, true);
        promoted = promoteInPattern(cl.pattern, used2);
      }
    }
    return { pattern: promoted, guard: cl.guard, body: cl.body };
  }

  static function promoteInPattern(p: EPattern, used: Map<String,Bool>): EPattern {
    return switch (p) {
      case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
        var base = nm.substr(1);
        if (used.exists(base)) PVar(base) else p;
      case PTuple(es):
        // Do NOT promote the classic {:atom, binder} payload slot; aliasing will handle body names
        var isClassicPayload = (es.length == 2) && (switch (es[0]) { case PLiteral(_): true; default: false; });
        if (isClassicPayload) PTuple([es[0], promoteOnlyIfNotSecondSlot(es[1], used)])
        else PTuple([for (e in es) promoteInPattern(e, used)]);
      case PList(es): PList([for (e in es) promoteInPattern(e, used)]);
      case PCons(h,t): PCons(promoteInPattern(h, used), promoteInPattern(t, used));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: promoteInPattern(kv.value, used) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: promoteInPattern(f.value, used) }]);
      case PPin(inner): PPin(promoteInPattern(inner, used));
      default: p;
    }
  }

  static function promoteOnlyIfNotSecondSlot(second:EPattern, used:Map<String,Bool>): EPattern {
    return switch (second) {
      case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
        // Keep payload binder underscored; alias pass will provide body-local names
        PVar(nm);
      default: promoteInPattern(second, used);
    }
  }

  static function collectUsedNames(body: ElixirAST): Map<String,Bool> {
    var used = new Map<String,Bool>();
    // Prefer builder-attached metadata when available
    try {
      var meta:Dynamic = body.metadata;
      if (meta != null && untyped meta.usedLocalsFromTyped != null) {
        var arr:Array<String> = untyped meta.usedLocalsFromTyped;
        for (n in arr) if (n != null && n.length > 0) used.set(n, true);
      }
    } catch (e:Dynamic) {}
    // AST variable uses
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): if (looksLower(v)) used.set(v, true);
        case EString(s): markInterpolations(s, used);
        case ERaw(code): markInterpolations(code, used);
        default:
      }
    });
    return used;
  }

  static inline function mergeInto(dst: Map<String,Bool>, src: Map<String,Bool>): Void {
    if (src == null) return;
    for (k in src.keys()) dst.set(k, true);
  }

  static function collectUnderscoredBases(p: EPattern): Array<String> {
    var out:Array<String> = [];
    function walk(pt:EPattern):Void {
      switch (pt) {
        case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'): out.push(nm.substr(1));
        case PTuple(es): for (e in es) walk(e);
        case PList(es): for (e in es) walk(e);
        case PCons(h,t): walk(h); walk(t);
        case PMap(kvs): for (kv in kvs) walk(kv.value);
        case PStruct(_, fs): for (f in fs) walk(f.value);
        case PPin(inner): walk(inner);
        default:
      }
    }
    walk(p);
    return out;
  }

  static function bodyContainsAny(ast: ElixirAST, bases: Array<String>): Bool {
    var found = false;
    inline function scanText(s:String):Void {
      if (found || s == null) return;
      for (b in bases) if (b != null && b.length > 0 && s.indexOf(b) != -1) { found = true; break; }
    }
    reflaxe.elixir.ast.ASTUtils.walk(ast, function(n: ElixirAST) {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EString(s): scanText(s);
        case ERaw(code): scanText(code);
        default:
      }
    });
    return found;
  }

  static inline function looksLower(name:String): Bool {
    if (name == null || name.length == 0) return false;
    var c = name.charAt(0);
    return c == c.toLowerCase();
  }

  static function markInterpolations(s:String, used:Map<String,Bool>):Void {
    if (s == null) return;
    var re = new EReg("\\#\\{([^}]*)\\}", "g");
    var pos = 0;
    while (re.matchSub(s, pos)) {
      var inner = re.matched(1);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var tpos = 0;
      while (tok.matchSub(inner, tpos)) {
        var id = tok.matched(0);
        if (looksLower(id)) used.set(id, true);
        tpos = tok.matchedPos().pos + tok.matchedPos().len;
      }
      pos = re.matchedPos().pos + re.matchedPos().len;
    }
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * CaseClauseUnusedBinderUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: in case/cond clauses, underscore simple binders
 *   that are not referenced in the clause body (e.g., {:ok, value} -> ...
 *   where `value` is never read).
 *
 * WHY
 * - Elixir warns about unused variables in pattern matches. Adding underscore
 *   prefix (_value) silences these warnings for intentionally unused binders.
 * - Uses VarUseAnalyzer for comprehensive usage detection across all AST node
 *   types including EMap, EFn, string interpolation, ERaw, etc.
 *
 * HOW
 * - For each case clause, check if pattern-bound variables are used in body
 * - Uses VarUseAnalyzer.stmtUsesVar for accurate detection (handles closures,
 *   maps, interpolations, etc.)
 * - If a variable is NOT used, prefix with underscore
 */
class CaseClauseUnusedBinderUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrut, clauses):
          var cls = [];
          for (c in clauses) cls.push(rewriteClause(c));
          makeASTWithMeta(ECase(scrut, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteClause(c: ECaseClause): ECaseClause {
    var used = collectUsedVars(c.body);
    var hasRaw = containsRaw(c.body);
    var newPat = underscoreUnusedInPattern(c.pattern, c.body, used, hasRaw);
    return { pattern: newPat, guard: c.guard, body: c.body };
  }

  static function underscoreUnusedInPattern(p: EPattern, body: ElixirAST, used: Map<String, Bool>, hasRaw: Bool): EPattern {
    return switch (p) {
      case PVar(n):
        if (n == null || n.length == 0) p;
        else if (n.charAt(0) == "_") p;
        else {
          // Fast path: use a single traversal of the clause body to collect used vars.
          // Only fall back to VarUseAnalyzer when ERaw is present (some late transforms may
          // encode variable references in raw nodes).
          var isUsed = hasRaw ? VarUseAnalyzer.stmtUsesVar(body, n) : nameIsUsed(used, n);
          isUsed ? p : PVar('_' + n);
        }
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, body, used, hasRaw)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, body, used, hasRaw)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, body, used, hasRaw), underscoreUnusedInPattern(t, body, used, hasRaw));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, body, used, hasRaw) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, body, used, hasRaw) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, body, used, hasRaw));
      default: p;
    }
  }

  static inline function snakeCase(s:String):String {
    if (s == null || s.length == 0) return s;
    var out = new StringBuf();
    for (i in 0...s.length) {
      var ch = s.charAt(i);
      var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
      if (isUpper && i > 0) out.add("_");
      out.add(ch.toLowerCase());
    }
    return out.toString();
  }

  static inline function camelCase(s:String):String {
    if (s == null || s.length == 0) return s;
    var parts = s.split("_");
    if (parts.length == 1) return s;
    var out = new StringBuf();
    for (i in 0...parts.length) {
      var p = parts[i];
      if (p.length == 0) continue;
      if (i == 0) out.add(p);
      else out.add(p.charAt(0).toUpperCase() + p.substr(1));
    }
    return out.toString();
  }

  static function nameIsUsed(used: Map<String, Bool>, name: String): Bool {
    if (used == null || name == null || name.length == 0) return false;
    if (used.exists(name)) return true;
    var sn = snakeCase(name);
    if (sn != name && used.exists(sn)) return true;
    var cc = camelCase(name);
    if (cc != name && cc != sn && used.exists(cc)) return true;
    if (name.charAt(0) == '_' && name.length > 1) {
      var base = name.substr(1);
      if (used.exists(base)) return true;
      var snBase = snakeCase(base);
      if (snBase != base && used.exists(snBase)) return true;
    } else {
      var underscored = '_' + name;
      if (used.exists(underscored)) return true;
    }
    return false;
  }

  static function containsRaw(body: ElixirAST): Bool {
    var found = false;
    function walk(n: ElixirAST): Void {
      if (n == null || found || n.def == null) return;
      switch (n.def) {
        case ERaw(_):
          found = true;
        case EPin(inner):
          walk(inner);
        case EBinary(Match, _left, rhs):
          walk(rhs);
        case EBinary(_, l, r):
          walk(l);
          walk(r);
        case EMatch(_pat, rhsExpr):
          walk(rhsExpr);
        case EBlock(ss) | EDo(ss):
          for (s in ss) walk(s);
        case EIf(c, t, e):
          walk(c);
          walk(t);
          if (e != null) walk(e);
        case ECase(expr, clauses):
          walk(expr);
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        case EWith(clauses, doBlock, elseBlock):
          for (wc in clauses) walk(wc.expr);
          walk(doBlock);
          if (elseBlock != null) walk(elseBlock);
        case ECall(tgt, _, args):
          if (tgt != null) walk(tgt);
          for (a in args) walk(a);
        case ERemoteCall(mod, _, args):
          walk(mod);
          for (a in args) walk(a);
        case EField(obj, _):
          walk(obj);
        case EAccess(obj, key):
          walk(obj);
          walk(key);
        case EKeywordList(pairs):
          for (p in pairs) walk(p.value);
        case EMap(pairs):
          for (p in pairs) {
            walk(p.key);
            walk(p.value);
          }
        case EStructUpdate(base, fields):
          walk(base);
          for (f in fields) walk(f.value);
        case ETuple(elems) | EList(elems):
          for (e in elems) walk(e);
        case EFn(clauses):
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        case ECond(clauses):
          for (cl in clauses) {
            walk(cl.condition);
            walk(cl.body);
          }
        case ERange(a, b, _):
          walk(a);
          walk(b);
        case EUnary(_, inner):
          walk(inner);
        case EParen(inner):
          walk(inner);
        case EPipe(l, r):
          walk(l);
          walk(r);
        case EUnless(c, b, e):
          walk(c);
          walk(b);
          if (e != null) walk(e);
        case EFor(gens, filters, body, into, _):
          for (g in gens) walk(g.expr);
          for (f in filters) walk(f);
          if (body != null) walk(body);
          if (into != null) walk(into);
        case ECapture(expr, _):
          walk(expr);
        default:
      }
    }
    walk(body);
    return found;
  }

  static function collectUsedVars(body: ElixirAST): Map<String, Bool> {
    var used = new Map<String, Bool>();
    function note(v: String): Void {
      if (v != null && v.length > 0) used.set(v, true);
    }
    function scanStringInterpolation(str: String): Void {
      if (str == null) return;
      var i = 0;
      while (i < str.length) {
        var idx = str.indexOf("#{", i);
        if (idx == -1) break;
        var j = str.indexOf("}", idx + 2);
        if (j == -1) break;
        var inner = str.substr(idx + 2, j - (idx + 2));
        // Extract identifiers from inside the interpolation.
        var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
        var tpos = 0;
        while (tok.matchSub(inner, tpos)) {
          note(tok.matched(0));
          var mp = tok.matchedPos();
          tpos = mp.pos + mp.len;
        }
        i = j + 1;
      }
    }
    function walk(n: ElixirAST): Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v):
          note(v);
        case EPin(inner):
          walk(inner);
        case ERaw(_):
          // Skip: handled via VarUseAnalyzer fallback when present
        case EString(str):
          scanStringInterpolation(str);
        case EBinary(Match, _left, rhs):
          walk(rhs);
        case EBinary(_, l, r):
          walk(l);
          walk(r);
        case EMatch(_pat, rhsExpr):
          walk(rhsExpr);
        case EBlock(ss) | EDo(ss):
          for (s in ss) walk(s);
        case EIf(c, t, e):
          walk(c);
          walk(t);
          if (e != null) walk(e);
        case ECase(expr, clauses):
          walk(expr);
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        case EWith(clauses, doBlock, elseBlock):
          for (wc in clauses) walk(wc.expr);
          walk(doBlock);
          if (elseBlock != null) walk(elseBlock);
        case ECall(tgt, _, args):
          if (tgt != null) walk(tgt);
          for (a in args) walk(a);
        case ERemoteCall(mod, _, args):
          walk(mod);
          for (a in args) walk(a);
        case EField(obj, _):
          walk(obj);
        case EAccess(obj, key):
          walk(obj);
          walk(key);
        case EKeywordList(pairs):
          for (p in pairs) walk(p.value);
        case EMap(pairs):
          for (p in pairs) {
            walk(p.key);
            walk(p.value);
          }
        case EStructUpdate(base, fields):
          walk(base);
          for (f in fields) walk(f.value);
        case ETuple(elems) | EList(elems):
          for (e in elems) walk(e);
        case EFn(clauses):
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        case ECond(clauses):
          for (cl in clauses) {
            walk(cl.condition);
            walk(cl.body);
          }
        case ERange(a, b, _):
          walk(a);
          walk(b);
        case EUnary(_, inner):
          walk(inner);
        case EParen(inner):
          walk(inner);
        case EPipe(l, r):
          walk(l);
          walk(r);
        case EUnless(c, b, e):
          walk(c);
          walk(b);
          if (e != null) walk(e);
        case EFor(gens, filters, body, into, _):
          for (g in gens) walk(g.expr);
          for (f in filters) walk(f);
          if (body != null) walk(body);
          if (into != null) walk(into);
        case ECapture(expr, _):
          walk(expr);
        default:
      }
    }
    walk(body);
    return used;
  }
}

#end

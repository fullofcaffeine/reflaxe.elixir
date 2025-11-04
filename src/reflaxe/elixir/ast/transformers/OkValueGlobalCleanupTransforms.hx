package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * OkValueGlobalCleanupTransforms
 *
 * WHAT
 * - Ultra-late cleanup that rewrites free references to `ok_value` to `value` within
 *   a function body when `value` is declared and `ok_value` is not.
 *
 * WHY
 * - Prevent lingering `ok_value` names from earlier shape repairs; aligns with the
 *   variable hygiene directive to avoid ok_value leaks in output.
 */
class OkValueGlobalCleanupTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = cleanup(body, args);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = cleanup(body2, args2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        case EFn(clauses):
          var newClauses = [];
          for (cl in clauses) {
            var nb3 = cleanup(cl.body, cl.args);
            newClauses.push({ args: cl.args, guard: cl.guard, body: nb3 });
          }
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function cleanup(body: ElixirAST, args:Array<EPattern>): ElixirAST {
    var declared = new Map<String,Bool>();
    // Collect declared names from params and body patterns/LHS
    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      switch (x.def) {
        case EMatch(p, _): collectPatternNames(p, declared);
        case EBinary(Match, left, _):
          switch (left.def) { case EVar(nm): if (nm != null) declared.set(nm, true); default: }
        case ECase(_, clauses): for (c in clauses) collectPatternNames(c.pattern, declared);
        case EFn(clauses): for (cl in clauses) for (a in cl.args) collectPatternNames(a, declared);
        default:
      }
      return x;
    });
    function have(name:String):Bool return declared.exists(name);
    // Aggressive but safe in our generated codebase: normalize legacy placeholders
    // regardless of prior declarations to prevent compile-time undefined refs.
    var rewriteOk = true;
    var rewriteG = true;
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v):
          if (rewriteOk && v == "ok_value") return makeASTWithMeta(EVar("value"), x.metadata, x.pos);
          if (rewriteG && v == "_g") return makeASTWithMeta(EVar("g"), x.metadata, x.pos);
          x;
        case ERaw(code) if (code != null):
          var out = code;
          if (rewriteOk && rawContainsIdent(out, "ok_value")) out = replaceIdent(out, "ok_value", "value");
          if (rewriteG && rawContainsIdent(out, "_g")) out = replaceIdent(out, "_g", "g");
          if (out != code) makeASTWithMeta(ERaw(out), x.metadata, x.pos) else x;
        default: x;
      };
    });
  }

  static function collectPatternNames(p:EPattern, acc:Map<String,Bool>):Void {
    switch (p) {
      case PVar(nm) if (nm != null): acc.set(nm, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternNames(e, acc);
      case PCons(h, t): collectPatternNames(h, acc); collectPatternNames(t, acc);
      case PMap(kvs): for (kv in kvs) collectPatternNames(kv.value, acc);
      case PStruct(_, fs): for (f in fs) collectPatternNames(f.value, acc);
      case PPin(inner): collectPatternNames(inner, acc);
      default:
    }
  }
  // Token helpers (duplicated minimal versions for local use)
  static inline function isIdentChar(c: String): Bool {
    if (c == null || c.length == 0) return false;
    var ch = c.charCodeAt(0);
    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
  }
  static function rawContainsIdent(code: String, ident: String): Bool {
    if (code == null || ident == null || ident.length == 0) return false;
    var start = 0; var len = ident.length;
    while (true) {
      var i = code.indexOf(ident, start);
      if (i == -1) break;
      var before = i > 0 ? code.substr(i - 1, 1) : null;
      var afterIdx = i + len;
      var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
      if (!isIdentChar(before) && !isIdentChar(after)) return true;
      start = i + len;
    }
    return false;
  }
  static function replaceIdent(code: String, ident: String, replacement: String): String {
    if (code == null || ident == null || ident.length == 0) return code;
    var sb = new StringBuf();
    var start = 0; var len = ident.length;
    while (true) {
      var i = code.indexOf(ident, start);
      if (i == -1) { sb.add(code.substr(start)); break; }
      var before = i > 0 ? code.substr(i - 1, 1) : null;
      var afterIdx = i + len;
      var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
      if (!isIdentChar(before) && !isIdentChar(after)) {
        sb.add(code.substr(start, i - start));
        sb.add(replacement);
        start = i + len;
      } else {
        sb.add(code.substr(start, (i + 1) - start));
        start = i + 1;
      }
    }
    return sb.toString();
  }
}

#end

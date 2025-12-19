package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseClauseCamelAliasToSnakeBinderTransforms
 *
 * WHAT
 * - In ECase clauses, when the pattern binds snake_case names (e.g., inner_error)
 *   and the clause body references only the camelCase counterpart (e.g., innerError)
 *   without a local declaration, prepend a clause‑local alias `innerError = inner_error`.
 *
 * WHY
 * - String interpolation may carry original Haxe camelCase identifiers that are
 *   not represented as AST variables. Rather than rewriting ERaw/strings, alias
 *   the camelCase name to the bound snake_case binder to keep output idiomatic
 *   and avoid undefined-variable errors. App‑agnostic and shape‑based.
 *
 * HOW
 * - For each ECase clause:
 *   1) Collect snake_case binders from the pattern.
 *   2) Compute camelCase names for those binders.
 *   3) If a camelCase name is referenced in the body (via ERaw/printed scan or EVar)
 *      and not declared, prepend `camel = snake` to the clause body.
 * - Skip tagged tuples {:tag, ...} to avoid fighting binder-promotion.
 */
class CaseClauseCamelAliasToSnakeBinderTransforms {
  public static function aliasPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(processClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function processClause(cl: ECaseClause): ECaseClause {
    // Skip tagged tuples {:tag, ...}; binder/rename passes handle better.
    var isTaggedTuple = switch (cl.pattern) { case PTuple(es): switch (es[0]) { case PLiteral(_): true; default: false; } default: false; };
    if (isTaggedTuple) return cl;

    var declared = collectDeclared(cl.pattern, cl.body);
    var snakeBinders = collectSnakeBinders(cl.pattern);
    if (snakeBinders.length == 0) return cl;
    var used = collectUsedTokens(cl.body);

    var prefix:Array<ElixirAST> = [];
    for (snake in snakeBinders) {
      var camel = toCamel(snake);
      if (!allow(camel)) continue;
      if (declared.exists(camel)) continue;
      if (used.exists(camel)) {
        prefix.push(makeAST(EBinary(Match, makeAST(EVar(camel)), makeAST(EVar(snake)))));
      }
    }
    if (prefix.length == 0) return cl;
    var newBody = switch (cl.body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock(prefix.concat(sts)), cl.body.metadata, cl.body.pos);
      case EDo(sts2): makeASTWithMeta(EDo(prefix.concat(sts2)), cl.body.metadata, cl.body.pos);
      default: makeASTWithMeta(EBlock(prefix.concat([cl.body])), cl.body.metadata, cl.body.pos);
    };
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }

  static function collectSnakeBinders(p:EPattern):Array<String> {
    var out:Array<String> = [];
    function walk(px:EPattern):Void {
      switch (px) {
        case PVar(n) if (n != null && n.indexOf("_") != -1): out.push(n);
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
    return out;
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function pat(px:EPattern):Void {
      switch (px) {
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
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) { case EMatch(pt,_): pat(pt); case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true); default: }
    });
    return m;
  }

  static function collectUsedTokens(body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    // EVar occurrences
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){ switch (x.def) { case EVar(v): if (allow(v)) m.set(v,true); default: } });
    // Interpolation/ERaw scan
    try {
      var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(body, 0);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var pos = 0;
      while (tok.matchSub(printed, pos)) {
        var id = tok.matched(0);
        if (allow(id)) m.set(id, true);
        pos = tok.matchedPos().pos + tok.matchedPos().len;
      }
    } catch (e) {}
    return m;
  }

  static inline function toCamel(s:String):String {
    if (s == null) return s;
    var parts = s.split("_");
    if (parts.length == 0) return s;
    var out = parts[0];
    for (i in 1...parts.length) if (parts[i].length > 0) out += parts[i].charAt(0).toUpperCase() + parts[i].substr(1);
    return out;
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
}

#end

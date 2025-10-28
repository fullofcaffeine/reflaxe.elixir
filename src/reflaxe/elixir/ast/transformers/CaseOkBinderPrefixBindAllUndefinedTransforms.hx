package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * CaseOkBinderPrefixBindAllUndefinedTransforms
 *
 * WHAT
 * - In ECase clauses shaped `{:ok, binder}`, prefix-bind all undefined simple
 *   lowercase locals referenced in the clause body to `binder` (excluding
 *   reserved names like socket/params).
 *
 * WHY
 * - Absolute-last safety net when align/rename passes did not land; ensures
 *   intended locals like `todo`/`updated_todo` resolve to the success binder.
 */
class CaseOkBinderPrefixBindAllUndefinedTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var binder = extractOkBinder(cl.pattern);
            if (binder != null) {
              var declared = new Map<String,Bool>();
              collectPatternDecls(cl.pattern, declared);
              collectLhsDeclsInBody(cl.body, declared);
              var used = collectUsed(cl.body);
              var undef:Array<String> = [];
              for (u in used.keys()) if (!declared.exists(u) && allow(u)) undef.push(u);
              if (undef.length > 0 && undef.length <= 3) {
                // debug removed
                var prefixes = [for (v in undef) makeAST(EBinary(Match, makeAST(EVar(v)), makeAST(EVar(binder))))];
                var newBody = switch (cl.body.def) {
                  case EBlock(sts): makeASTWithMeta(EBlock(prefixes.concat(sts)), cl.body.metadata, cl.body.pos);
                  case EDo(sts2): makeASTWithMeta(EDo(prefixes.concat(sts2)), cl.body.metadata, cl.body.pos);
                  default: makeASTWithMeta(EBlock(prefixes.concat([cl.body])), cl.body.metadata, cl.body.pos);
                };
                out.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                continue;
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function extractOkBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"): switch (es[1]) { case PVar(n): n; default: null; } default: null; }
      default: null;
    }
  }
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == 'socket' || name == 'params' || name == '_params' || name == 'event') return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
  static function collectPatternDecls(p:EPattern, vars:Map<String,Bool>):Void {
    switch (p) { case PVar(n): vars.set(n,true); case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars); case PCons(h,t): collectPatternDecls(h, vars); collectPatternDecls(t, vars); case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars); case PStruct(_,fs): for (f in fs) collectPatternDecls(f.value, vars); case PPin(inner): collectPatternDecls(inner, vars); default: }
  }
  static function collectLhsDeclsInBody(body:ElixirAST, vars:Map<String,Bool>):Void {
    ASTUtils.walk(body, function(x:ElixirAST){ switch (x.def) { case EMatch(p,_): collectPatternDecls(p, vars); case EBinary(Match, l,_): collectLhs(l, vars); default: } });
  }
  static function collectLhs(lhs:ElixirAST, vars:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): vars.set(n,true); case EBinary(Match, l2,_): collectLhs(l2, vars); default: }
  }
  static function collectUsed(body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    ASTUtils.walk(body, function(x:ElixirAST){ switch (x.def) { case EVar(n): if (allow(n)) m.set(n,true); default: } });
    // Fallback: scan printed body for additional identifiers that AST walk may miss (e.g., inside generated ERaw)
    try {
      var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(body, 0);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var pos = 0;
      while (tok.matchSub(printed, pos)) {
        var id = tok.matched(0);
        if (allow(id)) m.set(id, true);
        pos = tok.matchedPos().pos + tok.matchedPos().len;
      }
    } catch (e:Dynamic) {}
    return m;
  }
}

#end

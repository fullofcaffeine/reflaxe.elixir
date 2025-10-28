package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseSuccessBinderTupleSecondBindTransforms
 *
 * WHAT
 * - In a case clause shaped `{:ok, binder}`, if the clause body contains a
 *   two-element tuple literal `{:tag, v}` where the second element is a simple
 *   lowercase variable `v` that is undefined in the clause, prefix-bind
 *   `v = binder` to the clause body.
 *
 * WHY
 * - Common, idiomatic pattern: broadcasting or returning `{:ok, value}` and later
 *   using that `value` as the second element of a tagged tuple. If prior passes
 *   did not align/rename the binder, this safely establishes the intended local.
 *
 * HOW
 * - For each ECase clause with pattern `{:ok, PVar(binder)}`:
 *   - Collect declared names (pattern + LHS binds in body)
 *   - Scan body for ETuple of two elements with first a literal and second an
 *     EVar candidate `v` (allow-list: lowercase, not reserved)
 *   - If any candidate v is undefined, prefix `v = binder` and preserve body
 */
class ClauseSuccessBinderTupleSecondBindTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var okBinder = extractOkBinder(cl.pattern);
            if (okBinder != null) {
              var declared = new Map<String,Bool>();
              collectPatternDecls(cl.pattern, declared);
              collectLhsDeclsInBody(cl.body, declared);
              var candidates = findTupleSecondVars(cl.body);
              var chosen:Null<String> = null;
              for (v in candidates) if (!declared.exists(v) && allow(v)) { chosen = v; break; }
              if (chosen != null) {
                #if sys Sys.println('[ClauseSuccessBinderTupleSecondBind] prefix ' + chosen + ' = ' + okBinder); #end
                var prefix = makeAST(EBinary(Match, makeAST(EVar(chosen)), makeAST(EVar(okBinder))));
                var newBody = switch (cl.body.def) {
                  case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), cl.body.metadata, cl.body.pos);
                  case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), cl.body.metadata, cl.body.pos);
                  default: makeASTWithMeta(EBlock([prefix, cl.body]), cl.body.metadata, cl.body.pos);
                };
                out.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                continue;
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function extractOkBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"): switch (es[1]) { case PVar(n): n; default: null; }
          default: null;
        }
      default: null;
    }
  }
  static function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
  static function collectPatternDecls(p:EPattern, vars:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
      case PCons(h,t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
      case PPin(inner): collectPatternDecls(inner, vars);
      default:
    }
  }
  static function collectLhsDeclsInBody(body:ElixirAST, vars:Map<String,Bool>):Void {
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) { case EMatch(p,_): collectPatternDecls(p, vars); case EBinary(Match, l,_): collectLhs(l, vars); default: }
    });
  }
  static function collectLhs(lhs:ElixirAST, vars:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): vars.set(n,true); case EBinary(Match, l2,_): collectLhs(l2, vars); default: }
  }
  static function findTupleSecondVars(body:ElixirAST): Array<String> {
    var found:Map<String,Bool> = new Map();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      switch (x.def) {
        case ETuple(items) if (items.length == 2):
          switch (items[1].def) { case EVar(v): found.set(v, true); default: }
        default:
      }
    });
    return [for (k in found.keys()) k];
  }
}

#end

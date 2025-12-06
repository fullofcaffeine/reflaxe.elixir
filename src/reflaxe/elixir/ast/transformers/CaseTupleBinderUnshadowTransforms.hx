package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseTupleBinderUnshadowTransforms
 *
 * WHAT
 * - For case expressions that scrutinize a function argument (e.g., `case socket do`),
 *   if a tuple clause binds the same name as the argument in the second position
 *   (e.g., `{:tag, socket}`), rename that binder to `value` and, when the clause
 *   body references exactly one undefined lower-case local, prefix-bind that
 *   local to `value`.
 *
 * WHY
 * - Prevents shadowing of function args in tuple patterns and repairs bodies
 *   that expect a meaningful name (e.g., `todo`). Shape-based; no app coupling.
 */
class CaseTupleBinderUnshadowTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var params = argNameSet(args);
          var nb = rewriteBody(body, params);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var params2 = argNameSet(args2);
          var nb2 = rewriteBody(body2, params2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function argNameSet(args:Array<EPattern>): Map<String,Bool> {
    var s = new Map<String,Bool>();
    for (a in args) switch (a) { case PVar(n) if (n != null && n.length > 0): s.set(n, true); default: }
    return s;
  }

  static function rewriteBody(body: ElixirAST, params: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          // Trigger when scrutinizing a simple variable; avoid atoms/tuples/maps
          var scrName:Null<String> = switch (expr.def) { case EVar(v): v; default: null; };
          if (scrName == null) return x;
          var out:Array<ECaseClause> = [];
          for (c in clauses) out.push(repairClause(c, scrName));
          makeASTWithMeta(ECase(expr, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function repairClause(c:ECaseClause, scrutinee:String): ECaseClause {
    // If pattern matches {:atom, PVar(scrutinee)}, rename binder to value
    var binderName:Null<String> = null;
    var pat2 = switch (c.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) {
          case PVar(n) if (n == scrutinee):
            binderName = "value";
            PTuple([es[0], PVar(binderName)]);
          default: c.pattern;
        }
      default: c.pattern;
    };
    if (binderName == null) return c;
    // If body references exactly one undefined lower-case local, prefix bind it to value
    var declared = collectDeclared(pat2, c.body);
    var used = collectUsed(c.body);
    var undef:Array<String> = [];
    for (u in used.keys()) if (!declared.exists(u) && allowLocal(u)) undef.push(u);
    if (undef.length == 1) {
      var chosen = undef[0];
      var prefix = makeAST(EBinary(Match, makeAST(EVar(chosen)), makeAST(EVar(binderName))));
      var body2 = switch (c.body.def) {
        case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), c.body.metadata, c.body.pos);
        case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), c.body.metadata, c.body.pos);
        default: makeASTWithMeta(EBlock([prefix, c.body]), c.body.metadata, c.body.pos);
      };
      return { pattern: pat2, guard: c.guard, body: body2 };
    }
    return { pattern: pat2, guard: c.guard, body: c.body };
  }

  static function allowLocal(name:String): Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
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
    // Declarations in body (LHS of assignments)
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
    });
    return m;
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(ast, function(n: ElixirAST) {
      switch (n.def) {
        case EVar(v): names.set(v, true);
        default:
      }
    });
    return names;
  }
}

#end

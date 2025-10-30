package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoReturnSocketNormalizeTransforms
 *
 * WHAT
 * - In handle_info/2 clauses, normalize helper calls so the last argument is the
 *   function parameter `socket` rather than a duplicated payload binder. This
 *   avoids shapes like `update_todo_in_list(todo, todo)` and restores the
 *   intended `update_todo_in_list(todo, socket)` without app-specific heuristics.
 *
 * WHY
 * - Late name/binder alignment passes can accidentally duplicate the payload
 *   variable into argument positions. This conservative fix maintains the
 *   invariant that handle_info helpers receive the context socket as the final
 *   argument while keeping everything shape-only and framework-agnostic.
 *
 * HOW
 * - For `def handle_info(msg, socket)`:
 *   - Walk the body; when encountering a call (local or remote) with >=2 args
 *     where first and last args are the same lower-case variable and that var
 *     is not `socket`, rewrite the last arg to `socket`.
 */
class HandleInfoReturnSocketNormalizeTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleInfo2(name, args)):
          var socketVar = secondArgVar(args);
          var withCallsFixed = fixCalls(body, socketVar);
          var withReturnsFixed = fixReturns(withCallsFixed, socketVar);
          var withPatternHygiene = underscorePatternCollisions(withReturnsFixed, socketVar);
          makeASTWithMeta(EDef(name, args, guards, withPatternHygiene), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleInfo2(name2, args2)):
          var socketVar2 = secondArgVar(args2);
          var withCallsFixed2 = fixCalls(body2, socketVar2);
          var withReturnsFixed2 = fixReturns(withCallsFixed2, socketVar2);
          var withPatternHygiene2 = underscorePatternCollisions(withReturnsFixed2, socketVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, withPatternHygiene2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  static inline function secondArgVar(args:Array<EPattern>):String {
    return switch (args[1]) { case PVar(n): n; default: "socket"; };
  }

  static inline function isLowerIdent(v:String):Bool {
    if (v == null || v.length == 0) return false;
    var c = v.charAt(0);
    return c.toLowerCase() == c;
  }

  static function fixCalls(body: ElixirAST, socketVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length >= 2):
          var same = sameFirstLast(args);
          if (same != null && same != socketVar && isLowerIdent(same)) {
            var na = args.copy();
            na[na.length - 1] = makeAST(EVar(socketVar));
            makeASTWithMeta(ECall(target, fname, na), x.metadata, x.pos);
          } else x;
        case ERemoteCall(mod, fname2, args2) if (args2 != null && args2.length >= 2):
          var same2 = sameFirstLast(args2);
          if (same2 != null && same2 != socketVar && isLowerIdent(same2)) {
            var nb = args2.copy();
            nb[nb.length - 1] = makeAST(EVar(socketVar));
            makeASTWithMeta(ERemoteCall(mod, fname2, nb), x.metadata, x.pos);
          } else x;
        default:
          x;
      }
    });
  }

  static function fixReturns(body: ElixirAST, socketVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ETuple(items) if (items.length == 2):
          switch (items[0].def) {
            case EAtom(a) if ((a : String) == "noreply"):
              // Only rewrite when second element is a lower-case variable different from socket
              switch (items[1].def) {
                case EVar(v) if (v != socketVar && isLowerIdent(v)):
                  makeASTWithMeta(ETuple([ makeAST(EAtom(reflaxe.elixir.ast.naming.ElixirAtom.raw("noreply"))), makeAST(EVar(socketVar)) ]), x.metadata, x.pos);
                default: x;
              }
            default: x;
          }
        default:
          x;
      }
    });
  }

  static function underscorePatternCollisions(body: ElixirAST, socketVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(scrut, clauses):
          var newClauses:Array<ECaseClause> = [];
          for (cl in clauses) {
            var newPat = renamePVar(cl.pattern, socketVar, '_' + socketVar);
            var newBody = cl.body; // keep body; renaming the binder removes overshadowing and reveals param `socket`
            newClauses.push({ pattern: newPat, guard: cl.guard, body: newBody });
          }
          makeASTWithMeta(ECase(scrut, newClauses), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function renamePVar(p:EPattern, from:String, to:String):EPattern {
    return switch (p) {
      case PVar(n): (n == from) ? PVar(to) : p;
      case PTuple(items):
        var out = new Array<EPattern>();
        for (i in items) out.push(renamePVar(i, from, to));
        PTuple(out);
      case PList(items):
        var out = new Array<EPattern>();
        for (i in items) out.push(renamePVar(i, from, to));
        PList(out);
      case PCons(h, t): PCons(renamePVar(h, from, to), renamePVar(t, from, to));
      case PMap(kvs):
        var out = new Array<{key:ElixirAST, value:EPattern}>();
        for (kv in kvs) out.push({ key: kv.key, value: renamePVar(kv.value, from, to) });
        PMap(out);
      case PStruct(n, fields):
        var out = new Array<{key:String, value:EPattern}>();
        for (f in fields) out.push({ key: f.key, value: renamePVar(f.value, from, to) });
        PStruct(n, out);
      case PPin(inner): PPin(renamePVar(inner, from, to));
      default: p;
    }
  }

  static function sameFirstLast(args:Array<ElixirAST>):Null<String> {
    var firstName:Null<String> = null;
    switch (args[0].def) { case EVar(v): firstName = v; default: }
    if (firstName == null) return null;
    switch (args[args.length - 1].def) { case EVar(v2) if (v2 == firstName): return v2; default: }
    return null;
  }
}

#end

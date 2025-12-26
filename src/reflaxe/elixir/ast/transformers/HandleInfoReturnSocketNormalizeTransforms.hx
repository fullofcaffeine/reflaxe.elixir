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
	          var msgVar = firstArgVar(args);
	          var socketVar = secondArgVar(args);
	          var payloadBinders = collectPayloadBinders(body, msgVar, socketVar);
	          var withCallsFixed = fixCalls(body, socketVar);
	          var withReturnsFixed = fixReturns(withCallsFixed, socketVar, payloadBinders);
	          var withPatternHygiene = underscorePatternCollisions(withReturnsFixed, socketVar);
	          makeASTWithMeta(EDef(name, args, guards, withPatternHygiene), n.metadata, n.pos);
	        case EDefp(name, args, guards, body) if (isHandleInfo2(name, args)):
	          var msgVar = firstArgVar(args);
	          var socketVar = secondArgVar(args);
	          var payloadBinders = collectPayloadBinders(body, msgVar, socketVar);
	          var withCallsFixed = fixCalls(body, socketVar);
	          var withReturnsFixed = fixReturns(withCallsFixed, socketVar, payloadBinders);
	          var withPatternHygiene = underscorePatternCollisions(withReturnsFixed, socketVar);
	          makeASTWithMeta(EDefp(name, args, guards, withPatternHygiene), n.metadata, n.pos);
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

  static inline function firstArgVar(args:Array<EPattern>):String {
    return switch (args[0]) { case PVar(n): n; default: "msg"; };
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
	        case ERemoteCall(mod, remoteFunctionName, remoteArgs) if (remoteArgs != null && remoteArgs.length >= 2):
	          var duplicatedVar = sameFirstLast(remoteArgs);
	          if (duplicatedVar != null && duplicatedVar != socketVar && isLowerIdent(duplicatedVar)) {
	            var nb = remoteArgs.copy();
	            nb[nb.length - 1] = makeAST(EVar(socketVar));
	            makeASTWithMeta(ERemoteCall(mod, remoteFunctionName, nb), x.metadata, x.pos);
	          } else x;
	        default:
	          x;
	      }
	    });
	  }

  static function fixReturns(body: ElixirAST, socketVar:String, payloadBinders:Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ETuple(items) if (items.length == 2):
          switch (items[0].def) {
            case EAtom(a) if ((a : String) == "noreply"):
              // Only rewrite when the return variable is a payload binder from the
              // `case msg do ... end` patterns. This avoids clobbering legitimate
              // `next_socket` / `updated_socket` locals.
              switch (items[1].def) {
                case EVar(v) if (v != socketVar && isLowerIdent(v) && payloadBinders != null && payloadBinders.exists(v)):
                  makeASTWithMeta(
                    ETuple([
                      makeAST(EAtom(reflaxe.elixir.ast.naming.ElixirAtom.raw("noreply"))),
                      makeAST(EVar(socketVar))
                    ]),
                    x.metadata,
                    x.pos
                  );
                default: x;
              }
            default: x;
          }
        default:
          x;
      }
    });
  }

  static function collectPayloadBinders(body: ElixirAST, msgVar:String, socketVar:String): Map<String,Bool> {
    var out = new Map<String,Bool>();
    if (body == null) return out;

    function collectPatternVars(p:EPattern):Void {
      switch (p) {
        case PVar(name):
          if (name != null && name != msgVar && name != socketVar && name.charAt(0) != '_') out.set(name, true);
        case PTuple(items) | PList(items):
          for (it in items) collectPatternVars(it);
        case PCons(h, t):
          collectPatternVars(h);
          collectPatternVars(t);
        case PMap(kvs):
          for (kv in kvs) collectPatternVars(kv.value);
        case PStruct(_, fields):
          for (f in fields) collectPatternVars(f.value);
        case PPin(inner):
          collectPatternVars(inner);
        default:
      }
    }

    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase({def: EVar(v)}, clauses) if (v == msgVar):
          for (cl in clauses) collectPatternVars(cl.pattern);
          x;
        default:
          x;
      }
    });

    return out;
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
	    switch (args[args.length - 1].def) { case EVar(lastName) if (lastName == firstName): return lastName; default: }
	    return null;
	  }
	}

#end

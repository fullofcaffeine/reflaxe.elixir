package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoCaseBinderCollisionRepairTransforms
 *
 * WHAT
 * - In LiveView `handle_info/2` bodies, repair clauses that accidentally bind
 *   the tuple payload to the same name as a function argument (commonly
 *   `socket`), then mistakenly pass that argument as the first parameter to
 *   helper calls (e.g., `add_todo_to_list(socket, socket)`).
 *
 * WHY
 * - Binder–argument collisions shadow the function parameter and lead to
 *   invalid helper invocations and runtime errors when branch bodies later
 *   treat the payload as a struct (e.g., `todo.user_id`). The generic
 *   collision-avoid pass intentionally avoids rewriting bodies to prevent
 *   clobbering legitimate argument uses. However, in `handle_info/2` the helper
 *   shape is consistent: payload first, `socket` last. We can safely repair the
 *   clause locally without app-specific names.
 *
 * HOW
 * - Target only `def handle_info(msg, socket)` or `defp handle_info/2`.
 * - For each `case` clause with a two-tuple pattern `{:tag, <binder>}` where
 *   `<binder>` equals the function `socket` parameter name, rename the binder to
 *   `payload` (descriptive, avoids numeric suffixes).
 * - Within that clause body, rewrite local calls so that when the first and
 *   last arguments are both the `socket` variable, the first argument becomes
 *   the new binder (`payload`). Leave remote calls untouched to avoid false
 *   positives.
 * - This is shape-only and framework-agnostic; it does not key on any tag or
 *   helper name.
 *
 * EXAMPLES
 * Before:
 *   case parsed do
 *     {:todo_created, socket} -> add_todo_to_list(socket, socket)
 *   end
 * After:
 *   case parsed do
 *     {:todo_created, payload} -> add_todo_to_list(payload, socket)
 *   end
 */
class HandleInfoCaseBinderCollisionRepairTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleInfo2(name, args)):
          #if sys Sys.println('[HandleInfoBinderRepair] pass start in def handle_info/2'); #end
          var socketVar = secondArgVar(args);
          var repaired = rewriteCaseClauses(body, socketVar);
          makeASTWithMeta(EDef(name, args, guards, repaired), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleInfo2(name2, args2)):
          #if sys Sys.println('[HandleInfoBinderRepair] pass start in defp handle_info/2'); #end
          var socketVar2 = secondArgVar(args2);
          var repaired2 = rewriteCaseClauses(body2, socketVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, repaired2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  static inline function secondArgVar(args:Array<EPattern>):String {
    return switch (args[1]) { case PVar(n): n; default: "socket"; };
  }

  static function rewriteCaseClauses(body: ElixirAST, socketVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(scrut, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(repairClause(cl, socketVar));
          makeASTWithMeta(ECase(scrut, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function repairClause(c:ECaseClause, socketVar:String): ECaseClause {
    var renamed = renameTupleBinderIfCollides(c.pattern, socketVar);
    if (renamed == null) return c;
    #if sys Sys.println('[HandleInfoBinderRepair] Renamed tuple binder colliding with ' + socketVar + ' -> payload'); #end
    // Clause pattern was renamed; repair helper calls in body where arg0==argN==socket
    var fixedBody = fixLocalCalls(c.body, socketVar, /*newBinder*/ "payload");
    // Recurse to handle nested case statements inside the clause body
    var recursed = rewriteCaseClauses(fixedBody, socketVar);
    return { pattern: renamed, guard: c.guard, body: recursed };
  }

  static function renameTupleBinderIfCollides(p:EPattern, socketVar:String): Null<EPattern> {
    return switch (p) {
      case PTuple(items) if (items.length == 2):
        switch (items[1]) {
          case PVar(n) if (n == socketVar): PTuple([ items[0], PVar("payload") ]);
          case PPin(inner):
            switch (inner) {
              case PVar(n2) if (n2 == socketVar): PTuple([ items[0], PVar("payload") ]);
              default: null;
            }
          default: null;
        }
      default: null;
    }
  }

  static function fixLocalCalls(body: ElixirAST, socketVar:String, binderName:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length >= 2):
          var firstIsSock = switch (args[0].def) { case EVar(v) if (v == socketVar): true; default: false; };
          var lastIsSock = switch (args[args.length - 1].def) { case EVar(v2) if (v2 == socketVar): true; default: false; };
          var isLocal = (target == null); // only local helpers; remote calls (Module.func) untouched
          if (isLocal && firstIsSock && lastIsSock) {
            var na = args.copy();
            na[0] = makeAST(EVar(binderName));
            makeASTWithMeta(ECall(target, fname, na), x.metadata, x.pos);
          } else x;
        default:
          x;
      }
    });
  }
}

#end

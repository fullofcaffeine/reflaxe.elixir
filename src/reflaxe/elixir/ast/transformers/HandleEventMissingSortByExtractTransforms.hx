package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventMissingSortByExtractTransforms
 *
 * WHAT
 * - Repairs handle_event/3 callbacks that reference `sort_by` without binding it.
 *
 * WHY
 * - Recent hygiene passes can remove intermediate bindings while the body still
 *   calls `SafeAssigns.set_sort_by_and_resort(socket, sort_by)`, leading to
 *   undefined-variable compile errors in the generated Elixir.
 *
 * HOW
 * - For each handle_event/3 function whose body uses the identifier `sort_by`
 *   and lacks any declaration of `sort_by`, prepend a binding:
 *     sort_by = Map.get(params, "sort_by")
 *   using the params binder name from the function head (defaults to "params").
 *
 * EXAMPLES
 * Before (generated, invalid):
 *   def handle_event("sort_todos", params, socket) do
 *     {:noreply, recompute_visible(SafeAssigns.set_sort_by_and_resort(socket, sort_by))}
 *   end
 *
 * After:
 *   def handle_event("sort_todos", params, socket) do
 *     sort_by = Map.get(params, "sort_by")
 *     {:noreply, recompute_visible(SafeAssigns.set_sort_by_and_resort(socket, sort_by))}
 *   end
 */
class HandleEventMissingSortByExtractTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          makeASTWithMeta(EDef(name, args, guards, injectSortBy(args, body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          makeASTWithMeta(EDefp(name2, args2, guards2, injectSortBy(args2, body2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function injectSortBy(args:Array<EPattern>, body:ElixirAST):ElixirAST {
    // Fast exit if sort_by not referenced
    if (!usesVar(body, "sort_by")) return body;

    // Collect declared vars in head and body
    var declared = collectDeclared(body);
    for (a in args) switch (a) {
      case PVar(n): declared.set(n, true);
      default:
    }
    if (declared.exists("sort_by")) return body; // already bound

    var paramsVar = extractParamsVar(args);
    var bind = makeAST(EBinary(Match,
      makeAST(EVar("sort_by")),
      makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [
        makeAST(EVar(paramsVar)),
        makeAST(EString("sort_by"))
      ]))
    ));

    return prependStatement(body, bind);
  }

  static function extractParamsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) {
      return switch (args[1]) { case PVar(n): n; default: "params"; }
    }
    return "params";
  }

  static function collectDeclared(body:ElixirAST):Map<String,Bool> {
    var declared = new Map<String,Bool>();
    ASTUtils.walk(body, function(x:ElixirAST) {
      switch (x.def) {
        case EMatch(PVar(n), _): declared.set(n, true);
        case EBinary(Match, left, _): switch (left.def) {
            case EVar(n2): declared.set(n2, true);
            default:
          }
        default:
      }
    });
    return declared;
  }

  static function usesVar(body:ElixirAST, name:String):Bool {
    var found = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (found) return;
      switch (x.def) {
        case EVar(v) if (v == name): found = true;
        default:
      }
    });
    return found;
  }

  static function prependStatement(body:ElixirAST, stmt:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var ns = [stmt];
        ns = ns.concat(stmts);
        makeASTWithMeta(EBlock(ns), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock([stmt, body]), body.metadata, body.pos);
    }
  }
}

#end

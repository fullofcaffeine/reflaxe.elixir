package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventUndefinedValueToParamTransforms
 *
 * WHAT
 * - In def/defp handle_event/3, if no local binding named `value` exists,
 *   rewrite any occurrences of the identifier `value` to the head payload
 *   binder (second argument), i.e., `params` or `_params`.
 *
 * WHY
 * - Prevents undefined variable errors when late passes reintroduce the
 *   bare identifier `value` in wrapper code (e.g., id conversion branches).
 *
 * HOW
 * - For each handle_event/3 function, collect declared names from LHS
 *   patterns and matches in the body. If `value` is not declared, walk
 *   the body and replace EVar("value") with EVar(paramVar).
 */
class HandleEventUndefinedValueToParamTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          #if sys Sys.println('[HandleEventUndefinedValueToParam] visiting handle_event/3 def'); #end
          var paramVar = extractParamsVarName(args);
          var nb = rewrite(body, paramVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          #if sys Sys.println('[HandleEventUndefinedValueToParam] visiting handle_event/3 defp'); #end
          var paramVar2 = extractParamsVarName(args2);
          var nb2 = rewrite(body2, paramVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }

  static inline function extractParamsVarName(args:Array<EPattern>):String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(nm): nm; default: "params"; }
  }

  static function rewrite(body: ElixirAST, paramVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == "value"): makeASTWithMeta(EVar(paramVar), x.metadata, x.pos);
        default: x;
      }
    });
  }

  // (No declared-guard needed; this is an absolute-last repair scoped to handle_event/3 only.)
}

#end

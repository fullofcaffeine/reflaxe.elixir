package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventSortByFinalBindTransforms
 *
 * WHAT: Absolute-final safety net for handle_event/3 to ensure `sort_by` is bound
 *       when referenced in the body.
 * WHY: Earlier passes may drop helper binds; missing `sort_by` causes compile errors.
 * HOW: For each handle_event/3 whose body references `sort_by` and has no declaration
 *      of that name, prepend `sort_by = Map.get(paramsVar, "sort_by")`.
 */
class HandleEventSortByFinalBindTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          makeASTWithMeta(EDef(name, args, guards, ensureSortBy(args, body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body) if (isHandleEvent3(name, args)):
          makeASTWithMeta(EDefp(name, args, guards, ensureSortBy(args, body)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function ensureSortBy(args:Array<EPattern>, body:ElixirAST):ElixirAST {
    if (!usesVar(body, "sort_by")) return body;
    if (declaresVar(body, "sort_by")) return body;

    var paramsVar = extractParamsVar(args);
    var bind = makeAST(EBinary(Match,
      makeAST(EVar("sort_by")),
      makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [
        makeAST(EVar(paramsVar)),
        makeAST(EString("sort_by"))
      ]))
    ));
    return prepend(body, bind);
  }

  static function extractParamsVar(args:Array<EPattern>):String {
    return if (args != null && args.length >= 2) {
      switch (args[1]) { case PVar(n): n; default: "params"; }
    } else "params";
  }

  static function usesVar(body:ElixirAST, name:String):Bool {
    var found = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (found) return;
      switch (x.def) { case EVar(v) if (v == name): found = true; default: }
    });
    return found;
  }

  static function declaresVar(body:ElixirAST, name:String):Bool {
    var found = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (found) return;
      switch (x.def) {
        case EMatch(PVar(v), _expr) if (v == name):
          found = true;
        case EBinary(Match, lhs, _rhs):
          switch (lhs.def) {
            case EVar(v2) if (v2 == name):
              found = true;
            default:
          }
        default:
      }
    });
    return found;
  }

  static function prepend(body:ElixirAST, stmt:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock([stmt].concat(stmts)), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock([stmt, body]), body.metadata, body.pos);
    }
  }
}
#end

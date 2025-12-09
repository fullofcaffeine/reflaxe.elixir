package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventForceSortByBindingTransforms
 *
 * WHAT
 * - Ensures every handle_event/3 has a binding `sort_by = Map.get(params, "sort_by")`
 *   unless `sort_by` is already declared.
 *
 * WHY
 * - Some lowering paths still emit sort_by usages without introducing a binding,
 *   causing mix compile failures. This pass provides a deterministic fix before
 *   late hygiene/drop passes run.
 *
 * HOW
 * - For each handle_event/3, detect if sort_by is declared (head or body). If not,
 *   prepend the binding using the params binder name from the head (default "params").
 */
class HandleEventForceSortByBindingTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          makeASTWithMeta(EDef(name, args, guards, inject(args, body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          makeASTWithMeta(EDefp(name2, args2, guards2, inject(args2, body2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function inject(args:Array<EPattern>, body:ElixirAST):ElixirAST {
    var paramsVar = extractParamsVar(args);
    var declared = collectDeclared(body);
    for (a in args) switch (a) { case PVar(n): declared.set(n, true); default: }
    if (declared.exists("sort_by")) return body;

    var bind = makeAST(EBinary(Match, makeAST(EVar("sort_by")), makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [
      makeAST(EVar(paramsVar)),
      makeAST(EString("sort_by"))
    ]))));
    return prepend(body, bind);
  }

  static inline function extractParamsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) return switch (args[1]) { case PVar(n): n; default: "params"; };
    return "params";
  }

  static function collectDeclared(body:ElixirAST):Map<String,Bool> {
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) {
        case EMatch(PVar(n), _): declared.set(n, true);
        case EBinary(Match, lhs, _): switch (lhs.def) { case EVar(n2): declared.set(n2, true); default: }
        default:
      }
    });
    return declared;
  }

  static function prepend(body:ElixirAST, stmt:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock([stmt].concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo([stmt].concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([stmt, body]), body.metadata, body.pos);
    }
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventValueBindFromParamsTransforms
 *
 * WHAT
 * - Ensures a local `value` binding exists in handle_event/3 callbacks when the
 *   body references `value` but no binding is present.
 *
 * WHY
 * - LiveEvent lowering can rely on `value` as the raw params map, but later
 *   cleanup passes may drop the binding. Elixir then raises "undefined variable value".
 *
 * HOW
 * - For each handle_event/3 function: if `value` is referenced and no binding
 *   exists in head patterns or body assignments, prepend `value = paramsVar`
 *   where paramsVar is the second argument name (default "params").
 */
class HandleEventValueBindFromParamsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
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
    var needsValue = usesVar(body, "value");
    // Always insert sort_by unless already declared to avoid missing bindings.
    var needsSortBy = true;
    if (!needsValue && !needsSortBy) return body;
    var declared = collectDeclared(body);
    for (a in args) switch (a) {
      case PVar(n): declared.set(n, true);
      default:
    }
    var paramsVar = extractParamsVar(args);
    var inserts:Array<ElixirAST> = [];

    if (needsValue && !declared.exists("value")) {
      inserts.push(makeAST(EBinary(Match, makeAST(EVar("value")), makeAST(EVar(paramsVar)))));
    }
    if (!declared.exists("sort_by")) {
      inserts.push(makeAST(EBinary(Match, makeAST(EVar("sort_by")), makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [
        makeAST(EVar(paramsVar)),
        makeAST(EString("sort_by"))
      ])))));
    }

    if (inserts.length == 0) return body;
    return prepend(body, inserts);
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
        case EBinary(Match, lhs, _): switch (lhs.def) {
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

  static function prepend(body:ElixirAST, stmts:Array<ElixirAST>):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts0):
        makeASTWithMeta(EBlock(stmts.concat(stmts0)), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock(stmts.concat([body])), body.metadata, body.pos);
    }
  }
}

#end

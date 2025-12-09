package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventAndInfoMissingVarFinalTransforms
 *
 * WHAT
 * - Absolute-final safety net for LiveView callbacks:
 *   * handle_event/3: bind `value` and `sort_by` if referenced but undeclared.
 *   * handle_info/2: bind `s` to `socket` if referenced but undeclared.
 *
 * WHY
 * - Prevents late-stage hygiene rewrites from leaving unbound identifiers that
 *   crash mix compile (e.g., Map.get(value, "id"), SafeAssigns.set_sort_by...,
 *   optimistic toggle helpers using `s`).
 *
 * HOW
 * - Scans function bodies for the target identifiers; if referenced and not
 *   declared in head patterns or assignments, prepends the minimal binding:
 *     value   = paramsVar
 *     sort_by = Map.get(paramsVar, "sort_by")
 *     s       = socket
 */
class HandleEventAndInfoMissingVarFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          makeASTWithMeta(EDef(name, args, guards, fixHandleEvent(args, body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          makeASTWithMeta(EDefp(name2, args2, guards2, fixHandleEvent(args2, body2)), n.metadata, n.pos);
        case EDef(name3, args3, guards3, body3) if (isHandleInfo2(name3, args3)):
          makeASTWithMeta(EDef(name3, args3, guards3, fixHandleInfo(body3)), n.metadata, n.pos);
        case EDefp(name4, args4, guards4, body4) if (isHandleInfo2(name4, args4)):
          makeASTWithMeta(EDefp(name4, args4, guards4, fixHandleInfo(body4)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  // handle_event helpers
  static function fixHandleEvent(args:Array<EPattern>, body:ElixirAST):ElixirAST {
    var declared = collectDeclared(body);
    for (a in args) switch (a) { case PVar(n): declared.set(n, true); default: }
    var paramsVar = extractParamsVar(args);

    var stmts:Array<ElixirAST> = [];
    if (needsVar(body, declared, "value")) {
      stmts.push(makeAST(EBinary(Match, makeAST(EVar("value")), makeAST(EVar(paramsVar)))));
      declared.set("value", true);
    }
    if (needsVar(body, declared, "sort_by")) {
      stmts.push(makeAST(EBinary(Match, makeAST(EVar("sort_by")),
        makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [
          makeAST(EVar(paramsVar)),
          makeAST(EString("sort_by"))
        ]))
      )));
      declared.set("sort_by", true);
    }
    if (stmts.length == 0) return body;
    return prepend(body, stmts);
  }

  // handle_info helpers
  static function fixHandleInfo(body:ElixirAST):ElixirAST {
    var declared = collectDeclared(body);
    if (!needsVar(body, declared, "s")) return body;
    var bind = makeAST(EBinary(Match, makeAST(EVar("s")), makeAST(EVar("socket"))));
    return prepend(body, [bind]);
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

  static function needsVar(body:ElixirAST, declared:Map<String,Bool>, name:String):Bool {
    if (declared.exists(name)) return false;
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
      case EBlock(existing):
        makeASTWithMeta(EBlock(stmts.concat(existing)), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock(stmts.concat([body])), body.metadata, body.pos);
    }
  }
}

#end

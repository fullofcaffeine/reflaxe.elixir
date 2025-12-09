package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventEnsureValueBindingTransforms
 *
 * WHAT
 * - Ensures handle_event/3 bodies that reference `value` have a binding
 *   `value = paramsVar` prepended.
 *
 * WHY
 * - Some pipelines still reference `value` without a binding; binding it to
 *   params avoids undefined-variable errors and keeps semantics consistent.
 *
 * HOW
 * - For each handle_event/3, if `value` is used in the body and not declared
 *   in head patterns or body matches, prepend `value = paramsVar`.
 */
class HandleEventEnsureValueBindingTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var pv = paramsVar(args);
          var nb = injectValue(body, pv);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var pv2 = paramsVar(args2);
          var nb2 = injectValue(body2, pv2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function paramsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) return switch (args[1]) { case PVar(n): n; default: "params"; };
    return "params";
  }

  static function injectValue(body: ElixirAST, pv:String): ElixirAST {
    var declared = new Map<String,Bool>();
    ASTUtils.walk(body, function(x:ElixirAST) {
      switch (x.def) {
        case EMatch(PVar(n), _): declared.set(n, true);
        case EBinary(Match, lhs, _): switch (lhs.def) { case EVar(n2): declared.set(n2, true); default: }
        default:
      }
    });
    if (declared.exists("value")) return body;

    var usesValue = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (usesValue) return;
      switch (x.def) {
        case EVar(v) if (v == "value"): usesValue = true;
        default:
      }
    });
    if (!usesValue) return body;

    var bind = makeAST(EBinary(Match, makeAST(EVar("value")), makeAST(EVar(pv))));
    #if debug_handle_event_value
    Sys.println('[HandleEventEnsureValueBinding] inserted value binding using ' + pv);
    #end
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock([bind].concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo([bind].concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([bind, body]), body.metadata, body.pos);
    }
  }
}

#end

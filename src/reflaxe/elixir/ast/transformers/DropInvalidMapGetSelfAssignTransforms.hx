package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropInvalidMapGetSelfAssignTransforms
 *
 * WHAT
 * - Removes invalid assignments of the shape `Map.get(params, "key") = Map.get(params, "key")`
 *   that may be introduced by aggressive alignment passes.
 *
 * WHY
 * - Such assignments are not valid Elixir (LHS must be a bindable pattern) and cause
 *   compilation to fail. They are also pure no-ops semantically.
 *
 * HOW
 * - Walk inside function bodies. For block-like bodies (EBlock/EDo), filter statements and
 *   drop any EBinary(Match, lhs, rhs) where both sides are Map.get/2 calls with identical
 *   module/function and identical literal key argument. This is target-agnostic and
 *   app-agnostic.
 *
 * EXAMPLES
 * Before:
 *   def handle_event("sort_todos", params, socket) do
 *     Map.get(params, "sort_by") = Map.get(params, "sort_by")
 *     ...
 *   end
 * After:
 *   def handle_event("sort_todos", params, socket) do
 *     ...
 *   end
 */
class DropInvalidMapGetSelfAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = filterBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(privateName, privateArgs, privateGuards, privateBody):
          var newBody = filterBody(privateBody);
          makeASTWithMeta(EDefp(privateName, privateArgs, privateGuards, newBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function filterBody(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var out:Array<ElixirAST> = [];
        for (s in stmts) if (!isSelfAssignMapGet(s)) out.push(s);
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      case EDo(statements):
        var out:Array<ElixirAST> = [];
        for (stmt in statements) if (!isSelfAssignMapGet(stmt)) out.push(stmt);
        makeASTWithMeta(EDo(out), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function isSelfAssignMapGet(n: ElixirAST): Bool {
    return switch (n.def) {
      case EBinary(Match, lhs, rhs):
        var keyL = extractMapGetKey(lhs);
        var keyR = extractMapGetKey(rhs);
        keyL != null && keyR != null && keyL == keyR;
      default: false;
    }
  }

  static function extractMapGetKey(expr: ElixirAST): Null<String> {
    return switch (expr.def) {
      case ERemoteCall(mod, name, args):
        var isMap = switch (mod.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && name == "get" && args != null && args.length >= 2)
          switch (args[1].def) { case EString(s): s; default: null; } else null;
      case ECall(target, funcName, argsList):
        var isMapGet = (funcName == "get") && (target != null) && switch (target.def) { case EVar(m2): m2 == "Map"; default: false; };
        if (isMapGet && argsList != null && argsList.length >= 2)
          switch (argsList[1].def) { case EString(key): key; default: null; } else null;
      default: null;
    }
  }
}

#end

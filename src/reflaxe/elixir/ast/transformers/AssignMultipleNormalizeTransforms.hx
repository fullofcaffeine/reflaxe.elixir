package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignMultipleNormalizeTransforms
 *
 * WHAT
 * - Normalizes the pattern produced by assign_multiple/assign mapping when used in an assignment:
 *   left = (assigns = %{...}); Phoenix.Component.assign(socket, assigns)
 *   → left = Phoenix.Component.assign(socket, %{...})
 *
 * WHY
 * - Some expansions introduce an intermediate `assigns` alias and then perform a bare
 *   Phoenix.Component.assign/2 call, forgetting to rebind `left` to the assign result. This breaks
 *   downstream code that expects `left` to be the updated socket.
 *
 * HOW
 * - Scans function bodies for the sequence of two statements matching the shape above, and rewrites
 *   them into a single assignment to the original LHS. Runs late; app-agnostic and shape-based.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class AssignMultipleNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewrite(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var out:Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
          var cur = stmts[i];
          if (i + 1 < stmts.length) {
            var nxt = stmts[i+1];
            // cur: left = (assignsVar = map)
            // nxt: Phoenix.Component.assign(socketLike, assignsVar)
            var leftVar:Null<ElixirAST> = null;
            var assignsVarName:Null<String> = null;
            var mapNode:Null<ElixirAST> = null;
            switch (cur.def) {
              case EBinary(Match, l, {def: EBinary(Match, {def: EVar(av)}, m)}):
                leftVar = l; assignsVarName = av; mapNode = m;
              default:
            }
            if (leftVar != null && assignsVarName != null && mapNode != null) {
              switch (nxt.def) {
                case ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secArg]) if (mod == "Phoenix.Component"):
                  switch (secArg.def) {
                    case EVar(v) if (v == assignsVarName):
                      // Replace pair with: left = Phoenix.Component.assign(firstArg, mapNode)
                      var call = makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, mapNode]));
                      out.push(makeAST(EBinary(Match, leftVar, call)));
                      i += 2;
                      continue;
                    default:
                  }
                default:
              }
            }
          }
          out.push(cur);
          i++;
        }
        makeAST(EBlock(out));
      default:
        body;
    }
  }
}

#end


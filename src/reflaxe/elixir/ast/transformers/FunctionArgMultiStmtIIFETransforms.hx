package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionArgMultiStmtIIFETransforms
 *
 * WHAT
 * - Wrap function arguments that are multi-statement blocks in an immediately-invoked
 *   anonymous function: (fn -> ... end).()
 *
 * WHY
 * - Prevent invalid formatting where multi-line blocks printed as arguments split the call site,
 *   e.g. assignment followed by case/cond. Printer tries to recover, but AST-level wrapping is safer.
 *
 * HOW
 * - Visit ECall/ERemoteCall nodes and replace any arg that is EBlock/EDo with >1 statements
 *   (or EParen wrapping such) with an IIFE node.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class FunctionArgMultiStmtIIFETransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECall(target, fnName, args):
          makeASTWithMeta(ECall(target, fnName, wrapArgs(args)), n.metadata, n.pos);
        case ERemoteCall(mod, fnName, args):
          makeASTWithMeta(ERemoteCall(mod, fnName, wrapArgs(args)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function wrapArgs(args:Array<ElixirAST>): Array<ElixirAST> {
    if (args == null) return args;
    var out:Array<ElixirAST> = [];
    for (a in args) out.push(wrapIfBlock(a));
    return out;
  }

  static function wrapIfBlock(arg: ElixirAST): ElixirAST {
    if (arg == null) return arg;
    function isMultiBlock(x: ElixirAST): Bool {
      return switch (x.def) {
        case EBlock(stmts) | EDo(stmts): stmts != null && stmts.length > 1;
        case EParen(inner): isMultiBlock(inner);
        default: false;
      }
    }
    if (isMultiBlock(arg)) {
      var fn = makeAST(EFn([{ args: [], guard: null, body: arg }]));
      return makeAST(ECall(fn, "", []));
    }
    return arg;
  }
}

#end

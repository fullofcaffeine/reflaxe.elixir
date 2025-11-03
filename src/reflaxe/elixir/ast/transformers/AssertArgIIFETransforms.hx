package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssertArgIIFETransforms
 *
 * WHAT
 * - Wrap the first argument of Assert.is_true/1 and Assert.is_false/1 in an IIFE when
 *   the expression may expand to multiple statements (assignments + case/cond).
 *
 * WHY
 * - Prevent invalid formatting at call sites when inline expansions introduce
 *   multi-statement constructs for boolean checks.
 *
 * HOW
 * - Detect ERemoteCall(Assert, "is_true"|"is_false", [arg | rest]) and replace arg with
 *   (fn -> arg end).() when arg AST is not a trivial literal/var.
 */
class AssertArgIIFETransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(mod, fnName, args) if (isAssert(mod) && (fnName == "is_true" || fnName == "is_false") && args != null && args.length >= 1):
          var first = args[0];
          var wrapped = if (needsIIFE(first)) iife(first) else first;
          makeASTWithMeta(ERemoteCall(mod, fnName, [wrapped].concat(args.slice(1))), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isAssert(mod: ElixirAST): Bool {
    return switch (mod.def) { case EVar(m) if (m == "Assert"): true; default: false; }
  }

  static function needsIIFE(arg: ElixirAST): Bool {
    return switch (arg.def) {
      case EVar(_) | EInteger(_) | EBoolean(_) | EAtom(_) | EString(_): false;
      case EParen(inner): needsIIFE(inner);
      default: true; // be conservative: wrap all non-trivial expressions
    }
  }

  static inline function iife(body: ElixirAST): ElixirAST {
    var fn = makeAST(EFn([{ args: [], guard: null, body: body }]));
    return makeAST(ECall(fn, "", []));
  }
}

#end

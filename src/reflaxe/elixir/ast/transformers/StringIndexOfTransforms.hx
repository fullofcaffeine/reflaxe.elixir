package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StringIndexOfTransforms
 *
 * WHAT
 * - Rewrites `str.indexOf(sub) >= 0` and `> -1` patterns to idiomatic boolean
 *   checks using :binary.match/2: `:binary.match(str, sub) != :nomatch`.
 *
 * WHY
 * - Avoids ad-hoc assignment + case sequences in expression contexts (e.g.,
 *   function arguments), yielding cleaner and always-valid code.
 *
 * HOW
 * - Detect EBinary(GreaterEqual/GreaterThan, ECall(target, "indexOf", [sub]), EInteger(0 or -1))
 *   and replace the whole expression with `ERemoteCall(:binary, "match", [target, sub]) != :nomatch`.
 */
class StringIndexOfTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBinary(op, left, right):
          switch (left.def) {
            case ECall(target, "indexOf", args) if (args != null && args.length == 1):
              var sub = args[0];
              // Accept >= 0 or > -1
              var matches = (op == GreaterEqual && isZero(right)) || (op == Greater && isMinusOne(right));
              if (matches) {
                var binMod = makeAST(EVar(":binary"));
                var matchCall = makeAST(ERemoteCall(binMod, "match", [target, sub]));
                var nomatch = makeAST(EAtom(":nomatch"));
                makeASTWithMeta(EBinary(NotEqual, matchCall, nomatch), n.metadata, n.pos);
              } else n;
            default:
              n;
          }
        default:
          n;
      }
    });
  }

  static inline function isZero(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == 0): true; default: false; }
  }
  static inline function isMinusOne(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == -1): true; default: false; }
  }
}

#end

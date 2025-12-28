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

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class StringIndexOfTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBinary(op, left, right):
          // Accept >= 0 or > -1.
          var matches = (op == GreaterEqual && isZero(right)) || (op == Greater && isMinusOne(right));
          if (!matches) return n;

          // Primary form: str.indexOf(sub) >= 0
          switch (left.def) {
            case ECall(target, "indexOf", args) if (args != null && args.length == 1):
              return makeBinaryMatchNotNomatch(target, args[0], n);
            default:
          }

          // Lowered form: (case :binary.match(str, sub) do ... end) >= 0
          var lowered = extractBinaryMatchCall(left);
          if (lowered != null) {
            return makeBinaryMatchNotNomatch(lowered.target, lowered.sub, n);
          }

          n;
        default:
          n;
      }
    });
  }

  static function makeBinaryMatchNotNomatch(target: ElixirAST, sub: ElixirAST, original: ElixirAST): ElixirAST {
    var binMod = makeAST(EVar(":binary"));
    var matchCall = makeAST(ERemoteCall(binMod, "match", [target, sub]));
    var nomatch = makeAST(EAtom(":nomatch"));
    return makeASTWithMeta(EBinary(NotEqual, matchCall, nomatch), original.metadata, original.pos);
  }

  static inline function isBinaryModule(mod: ElixirAST): Bool {
    return switch (mod.def) {
      case EVar(m): (m == ":binary" || m == "binary");
      case EAtom(a):
        var s: String = a;
        s == ":binary" || s == "binary";
      default: false;
    };
  }

  static function unwrapParen(e: ElixirAST): ElixirAST {
    return switch (e.def) {
      case EParen(inner): unwrapParen(inner);
      default: e;
    };
  }

  static function extractBinaryMatchCall(expr: ElixirAST): Null<{ target: ElixirAST, sub: ElixirAST }> {
    var e = unwrapParen(expr);
    if (e == null || e.def == null) return null;
    return switch (e.def) {
      case ECase(matchExpr, _clauses):
        switch (unwrapParen(matchExpr).def) {
          case ERemoteCall(mod, fnName, margs) if (fnName == "match" && margs != null && margs.length == 2 && isBinaryModule(mod)):
            { target: margs[0], sub: margs[1] };
          case ECall(target, fnName, margs) if (target != null && fnName == "match" && margs != null && margs.length == 2 && isBinaryModule(target)):
            { target: margs[0], sub: margs[1] };
          default:
            null;
        }
      default:
        null;
    };
  }

  static inline function isZero(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == 0): true; default: false; }
  }
  static inline function isMinusOne(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == -1): true; default: false; }
  }
}

#end

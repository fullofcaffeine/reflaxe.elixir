package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * SanitizeAssignLhsIdentifierTransforms
 *
 * WHAT
 * - Ensures the left-hand side of `=` in statement context is a valid identifier; if not,
 *   rewrites it to `_` (discard), preserving side effects on the RHS.
 *
 * WHY
 * - Defensive guard against rare rename chains that yield invalid or empty identifiers
 *   in assignment position, which would render invalid Elixir like ` = expr`.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SanitizeAssignLhsIdentifierTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(sanitize(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(sanitize(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function sanitize(stmts:Array<ElixirAST>): Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (s in stmts) switch (s.def) {
      case EBinary(Match, left, right):
        var ok = false;
        switch (left.def) {
          case EVar(name) if (isValidIdent(name)):
            ok = true;
          default:
            var printed = ElixirASTPrinter.printAST(left);
            if (printed != null) {
              var t = StringTools.trim(printed);
              ok = isValidIdent(t);
            }
        }
        if (!ok) out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), right), s.metadata, s.pos)) else out.push(s);
      case EMatch(pat, rhs):
        var pat2 = switch (pat) {
          case PVar(nm) if (!isValidIdent(nm)): PVar("_");
          default: pat;
        };
        if (pat2 != pat) out.push(makeASTWithMeta(EMatch(pat2, rhs), s.metadata, s.pos)) else out.push(s);
      default:
        out.push(s);
    }
    return out;
  }

  static function isValidIdent(name:String): Bool {
    if (name == null) return false;
    if (name.length == 0) return false;
    var c0 = name.charAt(0);
    var lowerStart = c0.toLowerCase() == c0;
    if (!lowerStart) return false;
    for (i in 0...name.length) {
      var c = name.charCodeAt(i);
      var isAlpha = (c >= 'a'.code && c <= 'z'.code);
      var isDigit = (c >= '0'.code && c <= '9'.code);
      var isUnd = (c == '_'.code);
      if (!(isAlpha || isDigit || isUnd)) return false;
    }
    return true;
  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropNilAssignFromUnderscoredVarTransforms
 *
 * WHAT
 * - Removes statements of the form `nil = _var` which trigger the warning
 *   "the underscored variable `_var` is used after being set" in Phoenix.
 *
 * WHY
 * - Such assignments are no-ops used only to force evaluation; they are unnecessary
 *   and cause warnings under `--warnings-as-errors` (WAE). Dropping them is safe
 *   and keeps generated code idiomatic.
 *
 * HOW
 * - Walk EBlock/EDo statement lists and filter out EBinary(Match, left=EVar("nil"),
 *   right=EVar(name)) when `name` starts with an underscore.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DropNilAssignFromUnderscoredVarTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = clean(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = clean(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts, n)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2, n)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function clean(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(ss): makeASTWithMeta(EBlock(filter(ss, x)), x.metadata, x.pos);
        case EDo(ss2): makeASTWithMeta(EDo(filter(ss2, x)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function filter(stmts: Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
    if (stmts == null || stmts.length == 0) return stmts;
    var out: Array<ElixirAST> = [];
    for (s in stmts) {
      var drop = switch (s.def) {
        case EBinary(Match, left, right):
          var isNil = switch (left.def) {
            case EVar(nm) if (nm == "nil"): true;
            case EAtom(v) if (v == ":nil" || v == "nil"): true;
            case ENil: true;
            default: false;
          };
          var isUnderscored = switch (right.def) { case EVar(nm2) if (nm2 != null && nm2.length > 0 && nm2.charAt(0) == '_'): true; default: false; };
          isNil && isUnderscored;
        case EMatch(pat, rhs):
          var isNilPat = switch (pat) {
            case PVar(nm3) if (nm3 == "nil"): true;
            case PLiteral(lit): switch (lit.def) { case EAtom(v) if (v == ":nil" || v == "nil"): true; case ENil: true; default: false; };
            default: false;
          };
          var isUnderscoredRhs = switch (rhs.def) { case EVar(nm4) if (nm4 != null && nm4.length > 0 && nm4.charAt(0) == '_'): true; default: false; };
          isNilPat && isUnderscoredRhs;
        default: false;
      };
      if (!drop) out.push(s);
    }
    return out;
  }
}

#end

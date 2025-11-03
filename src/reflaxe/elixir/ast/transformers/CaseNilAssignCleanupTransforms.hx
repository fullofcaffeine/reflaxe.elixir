package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseNilAssignCleanupTransforms
 *
 * WHAT
 * - Removes leading or standalone statements inside case-clause bodies that match
 *   the shape `nil = _var` (or `:nil = _var`), which produce WAE warnings but have
 *   no effect.
 *
 * HOW
 * - Walk ECase; for each clause body that is an EBlock/EDo, filter statements by
 *   dropping any assignment where the LHS is the literal nil (EVar("nil") | ENil | :nil).
 */
class CaseNilAssignCleanupTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: cleanBody(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function cleanBody(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), b.metadata, b.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2)), b.metadata, b.pos);
      default: b;
    }
  }

  static function filter(stmts: Array<ElixirAST>): Array<ElixirAST> {
    var out: Array<ElixirAST> = [];
    for (s in stmts) {
      var drop = false;
      switch (s.def) {
        case EBinary(Match, left, right):
          drop = isNilLiteral(left) && isUnderscoredVar(right);
        case EMatch(pat, rhs):
          drop = isNilPattern(pat) && isUnderscoredVar(rhs);
        default:
      }
      if (!drop) out.push(s);
    }
    return out;
  }

  static inline function isUnderscoredVar(e: ElixirAST): Bool {
    return switch (e.def) { case EVar(nm) if (nm != null && nm.length > 0 && nm.charAt(0) == '_'): true; default: false; }
  }
  static inline function isNilLiteral(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(nm) if (nm == "nil"): true;
      case EAtom(v) if (v == ":nil" || v == "nil"): true;
      case ENil: true;
      default: false;
    }
  }
  static inline function isNilPattern(p: EPattern): Bool {
    return switch (p) {
      case PVar(n) if (n == "nil"): true;
      case PLiteral(l): switch (l.def) { case EAtom(v) if (v == ":nil" || v == "nil"): true; case ENil: true; default: false; }
      default: false;
    }
  }
}

#end


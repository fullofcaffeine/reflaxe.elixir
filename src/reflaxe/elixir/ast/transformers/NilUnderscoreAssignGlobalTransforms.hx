package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NilUnderscoreAssignGlobalTransforms
 *
 * WHAT
 * - Drops statements of the form `nil = _var` (or `:nil = _var`) anywhere inside
 *   blocks/do bodies. These are hygiene artifacts with no runtime effect and
 *   trigger warnings-as-errors in Phoenix.
 *
 * WHY
 * - Earlier passes may introduce placeholder binds in case arms that survive into
 *   function bodies. This absolute-final global sweep ensures such artifacts do
 *   not remain in the output regardless of local shapes.
 *
 * HOW
 * - Walk EBlock/EDo recursively and filter statements where the LHS is nil (ENil,
 *   EVar("nil"), or EAtom(":nil"/"nil")) and the RHS is an underscored variable.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class NilUnderscoreAssignGlobalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: clean(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function clean(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), b.metadata, b.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2)), b.metadata, b.pos);
      case EBinary(Match, left, right):
        // Clause body might be a single assignment; apply the same rewrite rules
        var isNil = switch (left.def) {
          case ENil: true;
          case EVar(nm) if (nm == "nil"): true;
          case EAtom(v) if (v == ":nil" || v == "nil"): true;
          default: false;
        };
        var isUnders = switch (right.def) {
          case EVar(nm2) if (nm2 != null && nm2.length > 0 && nm2.charAt(0) == '_'): true;
          default: false;
        };
        if (isNil && isUnders) {
          // Drop the whole assignment by replacing with `nil`
          makeASTWithMeta(ENil, b.metadata, b.pos);
        } else {
          switch (left.def) {
            case EVar(v) if (v == "socket"):
              if (isPutFlashOnSocket(right)) return right;
            default:
          }
          b;
        }
      case EMatch(PVar(name), right2):
        // Same logic for pattern-match assignments
        if (name != null && name.length > 0 && name.charAt(0) == '_' && isNilVar()) {
          return makeASTWithMeta(ENil, b.metadata, b.pos);
        } else if (name == "socket" && isPutFlashOnSocket(right2)) {
          return right2;
        } else b;
      default: b;
    }
  }

  static inline function isNilVar(): Bool {
    // Placeholder for symmetry; actual nil pattern handled above for EBinary only.
    return false;
  }

  static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      var drop = false;
      switch (s.def) {
        case EBinary(Match, left, right):
          var isNil = switch (left.def) {
            case ENil: true;
            case EVar(nm) if (nm == "nil"): true;
            case EAtom(v) if (v == ":nil" || v == "nil"): true;
            default: false;
          };
          var isUnders = switch (right.def) {
            case EVar(nm2) if (nm2 != null && nm2.length > 0 && nm2.charAt(0) == '_'): true;
            default: false;
          };
          if (isNil && isUnders) {
            drop = true;
          } else {
            // Rewrite `socket = Phoenix.LiveView.put_flash(socket, ...)` to just the call
            switch (left.def) {
              case EVar(v) if (v == "socket"):
                if (isPutFlashOnSocket(right)) {
                  out.push(right);
                  continue;
                }
              default:
            }
          }
        default:
      }
      if (!drop) out.push(s);
    }
    return out;
  }

  static inline function isPutFlashOnSocket(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall(target, fnName, args) if (fnName == "put_flash" && args != null && args.length >= 2):
        var isMod = switch (target.def) { case EVar(m) if (m == "Phoenix.LiveView"): true; default: false; };
        var firstIsSocket = switch (args[0].def) { case EVar(n) if (n == "socket"): true; default: false; };
        isMod && firstIsSocket;
      default: false;
    }
  }
}

#end

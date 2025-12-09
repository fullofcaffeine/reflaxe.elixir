package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleInfoMissingSocketVarTransforms
 *
 * WHAT
 * - Ensures a local `s` binding exists in handle_info/2 clauses when the body
 *   references `s` but no definition is present.
 *
 * WHY
 * - Certain hygiene passes can drop the `s = socket` helper binding used by
 *   LiveView optimistic toggle reconciliation, resulting in undefined-variable
 *   errors in generated Elixir.
 *
 * HOW
 * - For each handle_info/2 definition, if `s` is referenced and not declared in
 *   patterns or body assignments, prepend `s = socket` to the function body.
 *
 * EXAMPLE
 * Before:
 *   def handle_info(msg, socket) do
 *     ids = s.assigns.optimistic_toggle_ids
 *     ...
 *   end
 *
 * After:
 *   def handle_info(msg, socket) do
 *     s = socket
 *     ids = s.assigns.optimistic_toggle_ids
 *     ...
 *   end
 */
class HandleInfoMissingSocketVarTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleInfo2(name, args)):
          makeASTWithMeta(EDef(name, args, guards, injectSocket(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleInfo2(name2, args2)):
          makeASTWithMeta(EDefp(name2, args2, guards2, injectSocket(body2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  static function injectSocket(body:ElixirAST):ElixirAST {
    if (!usesVar(body, "s")) return body;
    var declared = collectDeclared(body);
    if (declared.exists("s")) return body;

    var bind = makeAST(EBinary(Match, makeAST(EVar("s")), makeAST(EVar("socket"))));
    return prependStatement(body, bind);
  }

  static function collectDeclared(body:ElixirAST):Map<String,Bool> {
    var declared = new Map<String,Bool>();
    ASTUtils.walk(body, function(x:ElixirAST) {
      switch (x.def) {
        case EMatch(PVar(n), _): declared.set(n, true);
        case EBinary(Match, lhs, _): switch (lhs.def) {
            case EVar(n2): declared.set(n2, true);
            default:
          }
        default:
      }
    });
    return declared;
  }

  static function usesVar(body:ElixirAST, name:String):Bool {
    var found = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (found) return;
      switch (x.def) {
        case EVar(v) if (v == name): found = true;
        default:
      }
    });
    return found;
  }

  static function prependStatement(body:ElixirAST, stmt:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var ns = [stmt];
        ns = ns.concat(stmts);
        makeASTWithMeta(EBlock(ns), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock([stmt, body]), body.metadata, body.pos);
    }
  }
}

#end

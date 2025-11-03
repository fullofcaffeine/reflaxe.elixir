package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebAliasAssignUnderscoreTransforms
 *
 * WHAT
 * - In Web.* modules, rewrite alias assignments to json/data/conn so that the
 *   left-hand variable is underscored (e.g., `json = v` → `_json = v`). This
 *   silences unused-variable warnings when such aliases are not consumed.
 */
class WebAliasAssignUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var out = [for (b in body) rewrite(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          makeASTWithMeta(EDefmodule(name2, rewrite(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0;
  }

  static function rewrite(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(v) if (isAlias(v)):
              var newLeft = makeASTWithMeta(EVar('_' + v), left.metadata, left.pos);
              makeASTWithMeta(EBinary(Match, newLeft, rhs), n.metadata, n.pos);
            default: n;
          }
        case EMatch(PVar(v2), rhs2) if (isAlias(v2)):
          makeASTWithMeta(EMatch(PVar('_' + v2), rhs2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isAlias(n:String): Bool {
    return n == "json" || n == "data" || n == "conn";
  }
}

#end


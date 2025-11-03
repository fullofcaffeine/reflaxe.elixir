package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefArgUnderscorePromoteByBodyUseTransforms
 *
 * WHAT
 * - If a function argument is an underscored variable (e.g., `_name`) but the
 *   function body references the base name (`name`) and not `_name`, promote the
 *   parameter binder to `name` and rewrite occurrences accordingly.
 *
 * WHY
 * - Avoid undefined-variable warnings when helper bodies use the base name while
 *   hygiene passes prefixed the argument. Keeps code idiomatic and consistent.
 *
 * HOW
 * - For each EDef/EDefp:
 *   1) For each argument pattern PVar(`_name`), check if body uses `name`.
 *   2) If used and `_name` is not used, rename binder to `name` and rewrite body
 *      references `_name`→`name`.
 */
class DefArgUnderscorePromoteByBodyUseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var renamed = promoteArgs(args, body);
          makeASTWithMeta(EDef(name, renamed.args, guards, renamed.body), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var renamed2 = promoteArgs(args2, body2);
          makeASTWithMeta(EDefp(name2, renamed2.args, guards2, renamed2.body), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function promoteArgs(args:Array<EPattern>, body:ElixirAST): {args:Array<EPattern>, body:ElixirAST} {
    if (args == null || args.length == 0) return {args: args, body: body};
    var outArgs = args.copy();
    var newBody = body;
    for (i in 0...outArgs.length) {
      switch (outArgs[i]) {
        case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
          var base = nm.substr(1);
          var usesBase = false;
          var usesUnders = false;
          ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
              case EVar(v) if (v == base): usesBase = true;
              case EVar(v2) if (v2 == nm): usesUnders = true;
              case ERaw(code):
                // Heuristic: ERaw interpolation contains base name usage (e.g., "#{... base ...}")
                if (code != null && code.indexOf(base) != -1) usesBase = true;
              default:
            }
            return x;
          });
          if (usesBase && !usesUnders) {
            #if debug_ast_transformer
            Sys.println('[DefArgUnderscorePromote] Renaming arg ' + nm + ' -> ' + base);
            #end
            outArgs[i] = PVar(base);
            newBody = ElixirASTTransformer.transformNode(newBody, function(x: ElixirAST): ElixirAST {
              return switch (x.def) {
                case EVar(v) if (v == nm): makeASTWithMeta(EVar(base), x.metadata, x.pos);
                default: x;
              }
            });
          }
        default:
      }
    }
    return {args: outArgs, body: newBody};
  }
}

#end

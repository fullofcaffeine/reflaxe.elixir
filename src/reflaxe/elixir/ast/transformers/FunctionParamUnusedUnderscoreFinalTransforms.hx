package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

using Lambda;

/**
 * FunctionParamUnusedUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: underscores unused function parameters in def/defp.
 *
 * WHY
 * - Eliminates warnings-as-errors for unused parameters (e.g., `event` in
 *   a handle_event/3 catch-all, or `online_users` in a render helper).
 *
 * HOW
 * - For each EDef/EDefp, use VarUseAnalyzer.stmtUsesVar to check if each parameter
 *   is referenced in the body. For each positional argument that is a simple PVar(name)
 *   and not used, rename it to PVar("_" + name).
 *
 * PHOENIX ~H TEMPLATE HANDLING
 * - Phoenix's ~H sigil implicitly requires a variable named `assigns` in scope
 * - The template uses @field syntax which accesses assigns.field
 * - VarUseAnalyzer cannot detect this implicit usage
 * - Therefore: if body contains ~H template, `assigns` parameter must NOT be prefixed
 *
 * USES VarUseAnalyzer
 * - This pass follows the project directive to use the centralized VarUseAnalyzer
 *   for all variable usage detection, ensuring proper coverage of:
 *   - EFn closure bodies
 *   - String interpolations (#{...})
 *   - ERaw token boundary search
 *   - All nested AST structures
 */
class FunctionParamUnusedUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var newArgs = underscoreUnusedParams(args, body);
          makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var newArgs2 = underscoreUnusedParams(args2, body2);
          makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  /**
   * Check each parameter and add underscore prefix if unused in body.
   * Uses VarUseAnalyzer.stmtUsesVar for comprehensive usage detection.
   *
   * Special case: if body contains Phoenix ~H template sigil, the `assigns`
   * parameter is implicitly used by Phoenix and must NOT be underscore-prefixed.
   */
  static function underscoreUnusedParams(args:Array<EPattern>, body:ElixirAST): Array<EPattern> {
    if (args == null) return args;

    // Check if body contains Phoenix ~H template (which implicitly uses assigns)
    var hasPhoenixTemplate = containsPhoenixTemplate(body);

    var out:Array<EPattern> = [];
    for (a in args) switch (a) {
      case PVar(paramName):
        // Phoenix ~H templates implicitly require assigns variable
        if (hasPhoenixTemplate && paramName == "assigns") {
          out.push(a); // Keep assigns unchanged - Phoenix needs it
        } else {
          // Use VarUseAnalyzer to check if parameter is used in body
          var isUsed = VarUseAnalyzer.stmtUsesVar(body, paramName);
          if (!isUsed && paramName.charAt(0) != '_') {
            out.push(PVar('_' + paramName));
          } else {
            out.push(a);
          }
        }
      default:
        out.push(a);
    }
    return out;
  }

  /**
   * Check if AST contains Phoenix ~H template sigil.
   * Phoenix's ~H sigil implicitly requires a variable named `assigns` in scope.
   */
  static function containsPhoenixTemplate(ast:ElixirAST):Bool {
    if (ast == null) return false;
    var found = false;

    ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (found) return n;
      switch (n.def) {
        case ERaw(code):
          // Check for ~H sigil (Phoenix component template)
          if (code != null && (code.indexOf('~H"') != -1 || code.indexOf("~H'") != -1 ||
              code.indexOf('~H"""') != -1 || code.indexOf("~H'''") != -1)) {
            #if debug_underscore_pass
            trace('[FunctionParamUnderscore] Found ~H template in ERaw');
            #end
            found = true;
          }
          #if debug_underscore_pass
          else if (code != null && code.length < 200) {
            trace('[FunctionParamUnderscore] ERaw code: ' + code.substr(0, 100));
          }
          #end
        case ESigil(sigilType, content, modifiers):
          // Also check ESigil node type for ~H templates
          if (sigilType == "H") {
            #if debug_underscore_pass
            trace('[FunctionParamUnderscore] Found ESigil ~H');
            #end
            found = true;
          }
        default:
      }
      return n;
    });

    return found;
  }
}

#end


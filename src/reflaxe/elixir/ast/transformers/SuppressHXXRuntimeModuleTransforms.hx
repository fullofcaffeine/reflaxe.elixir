package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SuppressHXXRuntimeModuleTransforms
 *
 * WHAT
 * - Marks the generated HXX module (std/HXX.hx) as compile-time only so the
 *   emitter skips writing hxx.ex. HXX.hxx()/block() are inlined and handled by the
 *   AST pipeline; no runtime module is needed in server outputs.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SuppressHXXRuntimeModuleTransforms {
  static function isSuppressedTemplateModule(name: String): Bool {
    if (name == null) return false;
    if (name == "HXX") return true;
    if (name == "HXX2" || name == "HeexTemplate") return true;
    // Accept fully qualified module names depending on printer/builder shape.
    if (StringTools.endsWith(name, ".HXX2")) return true;
    if (StringTools.endsWith(name, ".HeexTemplate")) return true;
    return false;
  }

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isSuppressedTemplateModule(name)):
          var meta = n.metadata;
          meta.suppressEmission = true;
          makeASTWithMeta(EModule(name, attrs, body), meta, n.pos);
	        case EDefmodule(name, doBlock) if (isSuppressedTemplateModule(name)):
	          var meta = n.metadata;
	          meta.suppressEmission = true;
	          makeASTWithMeta(EDefmodule(name, doBlock), meta, n.pos);
	        default:
	          n;
	      }
	    });
	  }
}

#end

package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StructModuleCaseNormalizeTransforms
 *
 * WHAT
 * - Normalizes struct module names to Elixir alias case (UpperCamel per segment).
 *   Example: %TodoApp.todo{} → %TodoApp.Todo{}.
 *
 * WHY
 * - Some earlier normalization passes may accidentally snake/lower a module
 *   segment carried as an AST expression before it is converted to a struct
 *   literal. Elixir requires aliases (segments starting with uppercase) as
 *   struct names; lowercased segments cause compile errors.
 *
 * HOW
 * - Visit EStruct(module, fields); if any dotted segment starts with a
 *   lowercase letter, capitalize that segment’s first letter. Leaves fully
 *   qualified names and standard library modules intact (they already follow
 *   alias casing). Does not touch field names or other nodes.
 */
class StructModuleCaseNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    inline function capFirst(s:String):String {
      if (s == null || s.length == 0) return s;
      var c = s.charAt(0);
      var cu = c.toUpperCase();
      var cl = c.toLowerCase();
      // Only change when first char is a letter and is lowercase
      if (c == cl && c != cu) return cu + s.substr(1); else return s;
    }
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EStruct(modName, fields):
          var newName = (function() {
            var parts = modName.split('.');
            if (parts.length <= 1) return modName;
            var changed = false;
            for (i in 0...parts.length) {
              var p = parts[i];
              var c = capFirst(p);
              if (c != p) { parts[i] = c; changed = true; }
            }
            return changed ? parts.join('.') : modName;
          })();
          if (newName != modName) makeASTWithMeta(EStruct(newName, fields), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }
}

#end


package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * RegistryCore
 *
 * WHAT
 * - Shared types and lightweight validators for the AST pass registry.
 *
 * WHY
 * - Keep registry composition maintainable as we modularize into groups while
 *   ensuring correctness (unique names, missing dependencies, cycles).
 *
 * HOW
 * - Provides validation helpers that operate on the existing PassConfig list.
 *   Does not change ordering (no behavior drift) — only validates and returns
 *   the original list.
 */
class RegistryCore {
  public static function validate(passes:Array<ElixirASTTransformer.PassConfig>):Array<ElixirASTTransformer.PassConfig> {
    // Unique names
    var seen = new Map<String,Bool>();
    for (p in passes) {
      if (p == null || p.name == null) continue;
      if (seen.exists(p.name)) {
        #if sys Sys.println('[RegistryCore] Duplicate pass name: ' + p.name); #end
      } else seen.set(p.name, true);
    }
    // Missing dependencies
    var names = new Map<String,Bool>();
    for (p in passes) if (p != null && p.name != null) names.set(p.name, true);
    for (p in passes) if (p != null && p.runAfter != null) {
      for (dep in p.runAfter) if (!names.exists(dep)) {
        #if sys Sys.println('[RegistryCore] Missing runAfter dependency: ' + dep + ' (referenced by ' + p.name + ')'); #end
      }
    }
    // Cycle detection (best-effort):
    var graph = new Map<String, Array<String>>();
    for (p in passes) {
      if (p == null || p.name == null) continue;
      graph.set(p.name, p.runAfter == null ? [] : p.runAfter.copy());
    }
    var visiting = new Map<String,Bool>();
    var visited = new Map<String,Bool>();
    function dfs(n:String, path:Array<String>):Void {
      if (visited.exists(n)) return;
      if (visiting.exists(n)) {
        #if sys Sys.println('[RegistryCore] Cycle detected: ' + (path.concat([n]).join(' -> '))); #end
        return;
      }
      visiting.set(n, true);
      var deps = graph.get(n);
      if (deps != null) for (d in deps) dfs(d, path.concat([n]));
      visiting.remove(n);
      visited.set(n, true);
    }
    for (k in graph.keys()) dfs(k, []);
    // Return as-is to preserve exact ordering (no behavior change)
    return passes;
  }
}
#end


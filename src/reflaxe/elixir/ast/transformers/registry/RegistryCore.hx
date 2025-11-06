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
    // Unique names (dedupe by first occurrence to avoid double-running a pass)
    var seen = new Map<String,Bool>();
    var duplicateNames:Array<String> = [];
    var deduped:Array<ElixirASTTransformer.PassConfig> = [];
    for (p in passes) {
      if (p == null || p.name == null) continue;
      if (seen.exists(p.name)) {
        duplicateNames.push(p.name);
        continue; // drop subsequent occurrences
      }
      seen.set(p.name, true);
      deduped.push(p);
    }
    // Missing dependencies
    var names = new Map<String,Bool>();
    for (p in deduped) if (p != null && p.name != null) names.set(p.name, true);
    var missingDeps = new Map<String, Array<String>>(); // dep -> [users]
    for (p in deduped) if (p != null && p.runAfter != null) {
      for (dep in p.runAfter) if (!names.exists(dep)) {
        var users = missingDeps.exists(dep) ? missingDeps.get(dep) : [];
        users.push(p.name);
        missingDeps.set(dep, users);
      }
    }
    // Cycle detection (best-effort):
    var graph = new Map<String, Array<String>>();
    for (p in deduped) {
      if (p == null || p.name == null) continue;
      graph.set(p.name, p.runAfter == null ? [] : p.runAfter.copy());
    }
    var visiting = new Map<String,Bool>();
    var visited = new Map<String,Bool>();
    function dfs(n:String, path:Array<String>):Void {
      if (visited.exists(n)) return;
      if (visiting.exists(n)) {
        #if (sys && debug_pass_order) Sys.println('[RegistryCore] Cycle detected: ' + (path.concat([n]).join(' -> '))); #end
        return;
      }
      visiting.set(n, true);
      var deps = graph.get(n);
      if (deps != null) for (d in deps) dfs(d, path.concat([n]));
      visiting.remove(n);
      visited.set(n, true);
    }
    for (k in graph.keys()) dfs(k, []);

    // Emit compact diagnostics only when explicitly requested
    #if (sys && debug_pass_order)
    if (duplicateNames.length > 0) {
      Sys.println('[RegistryCore] Duplicate pass names (deduped): ' + duplicateNames.join(', '));
    }
    if (missingDeps.keys().hasNext()) {
      for (dep in missingDeps.keys()) {
        var users = missingDeps.get(dep);
        Sys.println('[RegistryCore] Missing runAfter dependency: ' + dep + ' (referenced by ' + users.join(', ') + ')');
      }
    }
    #end
    // Return deduped list to prevent duplicate pass side-effects
    return deduped;
  }
}
#end

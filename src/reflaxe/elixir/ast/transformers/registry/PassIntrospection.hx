package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PassIntrospection
 *
 * WHAT
 * - Typed, minimal DTO for exposing the effective pass order to tooling
 *   without leaking internal PassConfig or requiring Dynamic.
 *
 * WHY
 * - Tools (run under --interp) should avoid depending on compiler internals
 *   and must honor the No‑Dynamic policy.
 *
 * HOW
 * - Maps ElixirASTPassRegistry.getEnabledPasses() → Array<PassInfo>
 *   (name + optional ordering hints). No behavior change.
 */
typedef PassInfo = {
  var name:String;
  @:optional var phase:String;
  @:optional var runAfter:Array<String>;
  @:optional var runBefore:Array<String>;
}

class PassIntrospection {
  public static function list():Array<PassInfo> {
    var enabled:Array<ElixirASTTransformer.PassConfig> = ElixirASTPassRegistry.getEnabledPasses();
    var out:Array<PassInfo> = [];
    for (p in enabled) {
      out.push({
        name: p.name,
        phase: p.phase,
        runAfter: p.runAfter,
        runBefore: p.runBefore
      });
    }
    return out;
  }
}
#end


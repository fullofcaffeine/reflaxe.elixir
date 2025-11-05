package tools;

import haxe.io.Path;

class RegistryOrderDoc {
  static inline var OUT:String = "docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md";

  /**
   * Pure Haxe/eval generator for the deterministic transform-pass order doc.
   *
   * - Runs under --interp (eval) on CI/dev.
   * - Requires only compiler registry classes; no JS/Node APIs.
   * - Gated by -D reflaxe_runtime so registry/group modules are available.
   */
  public static function main() {
    #if !reflaxe_runtime
    // Ensure groups/registry compiled for eval without target-specific classpaths
    throw 'Run with -D reflaxe_runtime to expose registry modules';
    #end
    var enabled:Array<reflaxe.elixir.ast.ElixirASTTransformer.PassConfig> =
      reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry.getEnabledPasses();

    var sb = new StringBuf();
    sb.add("# Transform Pass Registry Order\n\n");
    var ts = Date.now().toString();
    sb.add('Generated: ' + ts + "\n\n");
    var i = 0;
    for (p in enabled) {
      i++;
      sb.add(i + ". " + p.name + "\n");
    }
    var out = sb.toString();

    #if sys
    var dir = Path.directory(OUT);
    if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
    sys.io.File.saveContent(OUT, out);
    Sys.println('[registry-doc] Wrote ' + OUT + ' with ' + i + ' passes.');
    #else
    // Fallback for non-sys targets (not expected in CI)
    trace(out);
    #end
  }
}

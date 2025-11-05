package tools;

import haxe.io.Path;

class RegistryOrderDoc {
  static inline var OUT:String = "docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md";

  public static function main() {
    // Avoid pulling the full compiler type graph into the tool: ask the registry
    // directly and treat the result as Dynamic for extraction.
    var raw:Dynamic = untyped __js__("require"); // prevent DCE if not on JS
    var passes:Dynamic = untyped reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry.getEnabledPasses();
    var sb = new StringBuf();
    sb.add("# Transform Pass Registry Order\n\n");
    var ts = Date.now().toString();
    sb.add("Generated: " + ts + "\n\n");
    var i = 0;
    for (p in (passes : Array<Dynamic>)) {
      i++;
      sb.add(i + ". " + p.name);
      if (p.phase != null) sb.add("  (phase: " + p.phase + ")");
      sb.add("\n");
    }
    var out = sb.toString();
    #if js
    var fs = untyped __js__("require('fs')");
    var path = untyped __js__("require('path')");
    var dir = path.dirname(OUT);
    try { fs.mkdirSync(dir, untyped { recursive: true }); } catch (e:Dynamic) {}
    fs.writeFileSync(OUT, out);
    untyped __js__("console.log('[registry-doc] Wrote %s')", OUT);
    #else
    // Non-JS fallback (not used in CI): write via Haxe sys APIs
    #if sys
    var dir2 = Path.directory(OUT);
    if (!sys.FileSystem.exists(dir2)) sys.FileSystem.createDirectory(dir2);
    sys.io.File.saveContent(OUT, out);
    Sys.println('[registry-doc] Wrote ' + OUT);
    #end
    #end
  }
}

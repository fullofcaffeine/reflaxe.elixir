package tools;

import haxe.io.Path;

class RegistryOrderDoc {
  static inline var OUT:String = "docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md";

  /**
   * Pure Haxe/eval generator for the deterministic transform‑pass order doc.
   *
   * IMPLEMENTATION NOTE
   * - Avoids compiling the full compiler by parsing the registry source and group files.
   * - Runs under --interp with only sys APIs; no Node/JS required.
   */
  public static function main() {
    #if !sys
    throw 'This tool requires a sys target (use --interp).';
    #end

    final REG = 'src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx';
    final GROUP_DIR = 'src/reflaxe/elixir/ast/transformers/registry/groups';
    var reg = sys.io.File.getContent(REG);
    var lines = reg.split('\n');
    var order:Array<String> = [];

    function extractNamesFromGroup(groupFile:String):Array<String> {
      var txt = sys.io.File.getContent(groupFile);
      var names:Array<String> = [];
      var cursor = 0;
      while (true) {
        var namePos = txt.indexOf('name:', cursor);
        if (namePos < 0) break;
        var q1 = txt.indexOf('"', namePos);
        var q2 = txt.indexOf('"', q1 + 1);
        if (q1 > 0 && q2 > q1) {
          var nm = txt.substr(q1 + 1, q2 - q1 - 1);
          // Search forward for enabled flag in small window
          var windowEnd = txt.indexOf('});', q2);
          if (windowEnd < 0) windowEnd = q2 + 800; // generous window
          var window = txt.substr(q1, windowEnd - q1);
          if (window.indexOf('enabled: true') >= 0) names.push(nm);
          cursor = q2 + 1;
        } else {
          break;
        }
      }
      return names;
    }

    for (idx in 0...lines.length) {
      var line = lines[idx];
      // Expand groups.Foo.build()
      var gmarker = 'groups.';
      if (line.indexOf(gmarker) >= 0 && line.indexOf('.build()') > line.indexOf(gmarker)) {
        var start = line.indexOf(gmarker) + gmarker.length;
        var end = line.indexOf('.build()', start);
        var gname = StringTools.trim(line.substr(start, end - start));
        var gfile = GROUP_DIR + '/' + gname + '.hx';
        if (sys.FileSystem.exists(gfile)) for (n in extractNamesFromGroup(gfile)) order.push(n);
        continue;
      }
      // Inline pass entries
      if (line.indexOf('name:') >= 0) {
        var q1 = line.indexOf('"');
        var q2 = line.indexOf('"', q1 + 1);
        if (q1 > 0 && q2 > q1) {
          var nm = line.substr(q1 + 1, q2 - q1 - 1);
          var enabled:Null<Bool> = null;
          for (j in 0...6) {
            var k = idx + j;
            if (k >= lines.length) break;
            if (lines[k].indexOf('enabled: true') >= 0) { enabled = true; break; }
            if (lines[k].indexOf('enabled: false') >= 0) { enabled = false; break; }
          }
          if (enabled == true) order.push(nm);
        }
      }
    }

    var sb = new StringBuf();
    sb.add('# Transform Pass Registry Order\n\n');
    sb.add('Generated: ' + Date.now().toString() + "\n\n");
    var i = 0;
    for (n in order) { i++; sb.add(i + '. ' + n + "\n"); }

    var dir = Path.directory(OUT);
    if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
    sys.io.File.saveContent(OUT, sb.toString());
    Sys.println('[registry-doc] Wrote ' + OUT + ' with ' + i + ' passes.');
  }
}

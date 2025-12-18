package reflaxe.elixir.debug;

#if (macro || reflaxe_runtime)

class Perf {
  public static inline function now(): Float {
    return haxe.Timer.stamp() * 1000.0;
  }
  public static inline function add(label: String, startMs: Float): Void {
    var dur = now() - startMs;
    try {
      var f = sys.io.File.append("/tmp/haxe_perf.log");
      f.writeString(label + ":" + Std.string(dur) + "ms\n");
      f.close();
    } catch (_: haxe.Exception) {}
  }
}

#end

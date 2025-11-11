package;

using StringTools;
using Lambda;

class PrewarmDummy {
  static function main() {
    // Touch common std modules to prime typer/cache quickly
    var arr:Array<Int> = [];
    var kv = arr.keyValueIterator();
    for (_ in kv) {}
    var m:Map<String, Int> = new Map();
    m.set("a", 1);
    var s = " x ".trim();
    var b = haxe.io.Bytes.alloc(4);
    var re = ~/x/;
    var opt: haxe.ds.Option<Int> = haxe.ds.Option.None;
    var now = Date.now();
    var json = haxe.format.JsonPrinter.print({v: 1});
    // Prevent DCE on helpers
    if (s.length + b.length + (m.exists("a")?1:0) + (re.match("x")?1:0) + (json.length) + (opt == null?0:1) + now.getSeconds() == -1) {
      trace("noop");
    }
  }
}

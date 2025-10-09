import elixir.DateTime;

class Main {
  static function makeTs(left:String): String {
    var tmp: DateTime; // assigned in expression below
    var ts = left + (tmp = DateTime.utcNow());
    tmp.to_iso8601();
    return ts;
  }

  static function main() {
    makeTs("prefix-");
  }
}


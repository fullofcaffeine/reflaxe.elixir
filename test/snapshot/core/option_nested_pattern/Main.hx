package;

import haxe.ds.Option;

enum Inner {
  A(x: Int);
  B;
}

class Main {
  public static function eval(opt: Option<Inner>): Int {
    return switch (opt) {
      case Some(A(n)):
        n + 1;
      case Some(B):
        0;
      case None:
        -1;
    };
  }

  public static function main() {}
}


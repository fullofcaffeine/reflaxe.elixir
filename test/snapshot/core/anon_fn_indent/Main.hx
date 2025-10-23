package;

class Main {
  // Force a multi-line anonymous function via Array.map with a multi-line lambda
  public static function run(): Array<Int> {
    var xs = [1, 2, 3];
    // Multi-line body ensures printer uses multi-line fn formatting with proper end indentation
    var ys = xs.map(x -> {
      if (x > 1) {
        x + 1;
      } else {
        x - 1;
      }
    });
    return ys;
  }

  public static function main() {}
}

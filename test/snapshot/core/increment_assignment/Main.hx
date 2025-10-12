/**
 * Ensure increments compile to assignments
 *
 * We want `i++` and standalone `i + 1` statements to become
 * `i = i + 1` in generated Elixir.
 */
class Main {
    static function main() {
        var i = 0;
        // Statement increment pattern
        i++;
        i--;
        // Ensure inline arithmetic statements are rewritten
        i + 1; // should become i = i + 1
        i - 1; // should become i = i - 1
        trace(i);
    }
}


/**
 * Minimal test case to understand the exact pattern Haxe generates
 * when unrolling nested comprehensions with constant ranges
 * 
 * CURRENT BROKEN OUTPUT (lines 4-12 of generated Elixir):
 * ```elixir
 * g = []
 * g = g ++ [g = []
 * g ++ [0]    # <-- Invalid bare concatenation!
 * g ++ [1]    # <-- Invalid bare concatenation!
 * g]
 * g = g ++ [g = []
 * g ++ [0]    # <-- Invalid bare concatenation!
 * g ++ [1]    # <-- Invalid bare concatenation!
 * g]
 * ```
 * 
 * EXPECTED IDIOMATIC OUTPUT:
 * ```elixir
 * simple = for i <- 0..1 do
 *   for j <- 0..1 do
 *     j
 *   end
 * end
 * ```
 */
class TestMinimal {
    static function main() {
        // This should trigger the exact unrolling pattern
        var simple = [for (i in 0...2) [for (j in 0...2) j]];
        trace(simple);
    }
}
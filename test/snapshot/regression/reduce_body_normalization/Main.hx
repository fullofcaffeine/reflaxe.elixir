/**
 * Reduce-body normalization snapshot
 *
 * WHAT
 * - Produces a reducer body with head extraction `head = list[0]` so the
 *   ReduceBodySanitize pass can rewrite it to `head = binder`.
 * - Also exercises a straightforward accumulator pass-through.
 */

import elixir.Enum;

class Main {
    static function main() {
        var tags = ["a", "b", "c"];
        var out = Enum.reduce(tags, [], function(tag: String, acc: Array<String>) {
            var head = tags[0];
            // keep accumulator unchanged in this simple case
            return acc;
        });

        trace(out.length);
    }
}

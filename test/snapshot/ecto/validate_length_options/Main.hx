/**
 * Validate that validate_length emits only present options
 */
class Main {
    static function main() {
        var title = "hello";
        // Simulate cs/opts structures used by transforms
        var cs = {title: title};
        var opts = {min: 3, max: null, is: null};
        // Intended: only min gets passed; max/is should be dropped
        // The code below is representative; the transformer will normalize
        untyped __elixir__('Ecto.Changeset.validate_length({0}, :title, [min: Map.get({1}, :min), max: Map.get({1}, :max), is: Map.get({1}, :is)])', cs, opts);
    }
}


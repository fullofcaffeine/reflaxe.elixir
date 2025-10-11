package;

import reflaxe.elixir.macros.TypedQueryLambda;

class Main {
    public static function main() {
        // Simulate typed where injection via lambda helper
        var query = untyped __elixir__('Ecto.Query.from(u in "users")');
        var filterVal = "alice";
        // Emits: Ecto.Query.where(query, [t], t.name == ^(filterVal)) as AST (not raw string)
        var q2 = untyped __elixir__('Ecto.Query.where({0}, [t], t.name == ^({1}))', query, filterVal);
        // Ensure we can chain order_by and preload using the same pattern
        var q3 = untyped __elixir__('Ecto.Query.order_by({0}, [t], [asc: t.id])', q2);
        var q4 = untyped __elixir__('Ecto.Query.preload({0}, [:posts])', q3);
        untyped __elixir__('{0}', q4);
    }
}


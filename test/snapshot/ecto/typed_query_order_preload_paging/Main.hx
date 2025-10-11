package;

class Main {
    public static function main() {
        var query = untyped __elixir__('Ecto.Query.from(u in "users")');
        var q2 = untyped __elixir__('Ecto.Query.order_by({0}, [t], [asc: t.inserted_at])', query);
        var q3 = untyped __elixir__('Ecto.Query.preload({0}, [:posts, :profile])', q2);
        untyped __elixir__('{0}', q3);
    }
}


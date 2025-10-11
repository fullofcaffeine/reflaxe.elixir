package;

class Main {
    public static function main() {
        var query = untyped __elixir__('Ecto.Query.from(u in "users")');
        var value = 123;
        // Intentionally invalid field: t.no_such_field
        var q2 = untyped __elixir__('Ecto.Query.where({0}, [t], t.no_such_field == ^({1}))', query, value);
        untyped __elixir__('{0}', q2);
    }
}


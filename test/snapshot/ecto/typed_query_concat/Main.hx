package;

class Main {
    public static function main() {
        var query = untyped __elixir__('Ecto.Query.from(u in "users")');
        var name = "alice";
        var like = untyped __elixir__('"%" <> {0} <> "%"', name);
        var q2 = untyped __elixir__('Ecto.Query.where({0}, [t], t.name == ^({1}))', query, like);
        untyped __elixir__('{0}', q2);
    }
}


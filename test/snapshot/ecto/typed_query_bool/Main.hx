package;

class Main {
    public static function main() {
        var query = untyped __elixir__('Ecto.Query.from(u in "users")');
        var flag = true;
        var q2 = untyped __elixir__('Ecto.Query.where({0}, [t], t.active == ^({1}))', query, flag);
        untyped __elixir__('{0}', q2);
    }
}


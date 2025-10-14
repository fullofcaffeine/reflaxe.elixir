package;

class Main {
    public static function main() {
        var q = untyped __elixir__('Ecto.Query.from(t in "todos")');
        var i = 3;
        var b = true;

        var q_ne = untyped __elixir__('Ecto.Query.where({0}, [t], t.priority != ^({1}))', q, i);
        var q_lt = untyped __elixir__('Ecto.Query.where({0}, [t], t.priority < ^({1}))', q, i);
        var q_lte = untyped __elixir__('Ecto.Query.where({0}, [t], t.priority <= ^({1}))', q, i);
        var q_gt = untyped __elixir__('Ecto.Query.where({0}, [t], t.priority > ^({1}))', q, i);
        var q_gte = untyped __elixir__('Ecto.Query.where({0}, [t], t.priority >= ^({1}))', q, i);

        var q_and = untyped __elixir__('Ecto.Query.where({0}, [t], t.completed and ^({1}))', q, b);
        var q_or = untyped __elixir__('Ecto.Query.where({0}, [t], t.completed or ^({1}))', q, b);
        var q_not = untyped __elixir__('Ecto.Query.where({0}, [t], not ^({1}))', q, b);

        untyped __elixir__('{0}', q_ne);
        untyped __elixir__('{0}', q_lt);
        untyped __elixir__('{0}', q_lte);
        untyped __elixir__('{0}', q_gt);
        untyped __elixir__('{0}', q_gte);
        untyped __elixir__('{0}', q_and);
        untyped __elixir__('{0}', q_or);
        untyped __elixir__('{0}', q_not);
    }
}


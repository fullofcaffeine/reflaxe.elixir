package phoenix;

@:native("Phoenix.Sorting")
@:keep
class Sorting {
  public static function by(sortBy: String, todos: Array<server.schemas.Todo>): Array<server.schemas.Todo> {
    return switch (sortBy) {
      case "priority": byPriorityThenIdDesc(todos);
      case "due_date": byDueDateThenIdDesc(todos);
      case _: byCreatedNewest(todos);
    }
  }

  public static function byPriorityThenIdDesc(todos: Array<server.schemas.Todo>): Array<server.schemas.Todo> {
    return untyped __elixir__('Enum.sort_by({0}, fn t -> { case t.priority do "high" -> 0; "medium" -> 1; "low" -> 2; _ -> 3 end, -t.id } end)', todos);
  }

  public static function byDueDateThenIdDesc(todos: Array<server.schemas.Todo>): Array<server.schemas.Todo> {
    return untyped __elixir__('Enum.sort_by({0}, fn t -> { is_nil(t.due_date), t.due_date || ~N[0000-01-01 00:00:00], -t.id } end)', todos);
  }

  public static function byCreatedNewest(todos: Array<server.schemas.Todo>): Array<server.schemas.Todo> {
    // Newest first (descending by inserted_at), nils last; break ties by id desc
    // Use a composite key and a descending comparator to avoid ad-hoc hashing
    return untyped __elixir__(
      'Enum.sort_by({0}, fn t -> { not is_nil(t.inserted_at), t.inserted_at || ~N[0000-01-01 00:00:00], t.id } end, &>=/2)'
      , todos
    );
  }
}

package phoenix;

/**
 * Sorting utilities for todo lists.
 *
 * Uses extern inline pattern to directly inject Elixir code at call sites,
 * avoiding the need for a separate Phoenix.Sorting module at runtime.
 */
extern class Sorting {
  /**
   * Sort todos by the specified sort key.
   * @param sortBy Sort key: "priority", "due_date", or default (created newest)
   * @param todos Array of todos to sort
   * @return Sorted array
   */
  extern inline public static function by(sortBy: String, todos: Array<Dynamic>): Array<Dynamic> {
    return untyped __elixir__('
      case {0} do
        "priority" -> Enum.sort_by({1}, fn t -> { case t.priority do "low" -> 0; "medium" -> 1; "high" -> 2; _ -> 3 end, -t.id } end)
        "due_date" -> Enum.sort_by({1}, fn t -> { is_nil(t.due_date), t.due_date || ~N[0000-01-01 00:00:00], -t.id } end)
        _ -> Enum.sort_by({1}, fn t -> { not is_nil(t.inserted_at), t.inserted_at || ~N[0000-01-01 00:00:00], t.id } end, &>=/2)
      end
    ', sortBy, todos);
  }

  extern inline public static function byPriorityThenIdDesc(todos: Array<Dynamic>): Array<Dynamic> {
    return untyped __elixir__('Enum.sort_by({0}, fn t -> { case t.priority do "low" -> 0; "medium" -> 1; "high" -> 2; _ -> 3 end, -t.id } end)', todos);
  }

  extern inline public static function byDueDateThenIdDesc(todos: Array<Dynamic>): Array<Dynamic> {
    return untyped __elixir__('Enum.sort_by({0}, fn t -> { is_nil(t.due_date), t.due_date || ~N[0000-01-01 00:00:00], -t.id } end)', todos);
  }

  extern inline public static function byCreatedNewest(todos: Array<Dynamic>): Array<Dynamic> {
    return untyped __elixir__(
      'Enum.sort_by({0}, fn t -> { not is_nil(t.inserted_at), t.inserted_at || ~N[0000-01-01 00:00:00], t.id } end, &>=/2)'
      , todos
    );
  }
}

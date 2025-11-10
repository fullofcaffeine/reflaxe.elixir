defmodule TodoApp.Sorting do
  def by(sort_by, todos) do
    (case sort_by do
      "due_date" ->
        by_due_date_then_id_desc(todos)
      "priority" ->
        by_priority_then_id_desc(todos)
      _ ->
        by_created_newest(todos)
    end)
  end
  def by_priority_then_id_desc(todos) do
    Enum.sort_by(todos, fn t -> { case t.priority do "high" -> 0; "medium" -> 1; "low" -> 2; _ -> 3 end, -t.id } end)
  end
  def by_due_date_then_id_desc(todos) do
    Enum.sort_by(todos, fn t -> { is_nil(t.due_date), t.due_date || ~N[0000-01-01 00:00:00], -t.id } end)
  end
  def by_created_newest(todos) do
    Enum.sort_by(todos, fn t -> { not is_nil(t.inserted_at), t.inserted_at || ~N[0000-01-01 00:00:00], t.id } end, &>=/2)
  end
end

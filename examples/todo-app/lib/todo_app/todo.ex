defmodule TodoApp.Todo do
  def changeset(todo, params) do
    temp_changeset = nil
    this1 = Ecto.Changeset.change(todo, params)
    temp_changeset = this1
    cs = tempChangeset
    temp_result = nil
    temp_changeset1 = nil
    this1 = Ecto.Changeset.validate_required(cs, Enum.map(["title", "userId"], &String.to_atom/1))
    opts = %{:min => 3, :max => 200}
    if (:nil) do
      :nil
    else
      if (:nil) do
        :nil
      else
        if (:nil), do: :nil, else: :nil
      end
    end
    this1 = :nil
    opts = %{:max => 1000}
    if (:nil) do
      :nil
    else
      if (:nil) do
        :nil
      else
        if (:nil), do: :nil, else: :nil
      end
    end
    :nil
  end
  def toggle_completed(todo) do
    params = %{:completed => not todo.completed}
    TodoApp.Todo.changeset(todo, params)
  end
  def update_priority(todo, priority) do
    params = %{:priority => priority2}
    TodoApp.Todo.changeset(todo, params)
  end
  def add_tag(todo, tag) do
    temp_array = nil
    if (todo.tags != nil) do
      temp_array = todo.tags
    else
      temp_array = []
    end
    tempArray = tempArray ++ [tag]
    params = %{:tags => tempArray}
    TodoApp.Todo.changeset(todo, params)
  end
end
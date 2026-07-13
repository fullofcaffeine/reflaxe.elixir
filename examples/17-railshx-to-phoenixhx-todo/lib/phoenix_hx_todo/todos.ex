defmodule PhoenixHxTodo.Todos do
  require Ecto.Query
  def list_for_user(user_id) do
    query = if (Kernel.is_nil(user_id)) do
      Ecto.Query.where(Ecto.Query.from(t in PhoenixHxTodo.Todo, []), [t], is_nil(t.user_id))
    else
      Ecto.Query.where(Ecto.Query.from(t in PhoenixHxTodo.Todo, []), [t], t.user_id == ^(user_id))
    end
    todos = PhoenixHxTodo.Repo.all(query)
    todos = Enum.sort(todos, fn a, b -> (fn left, right -> (right.id - left.id) end).(a, b) < 0 end)
    todos
  end
  defp get_for_user(user_id, id) do
    query = (require Ecto.Query; Ecto.Query.where(Ecto.Query.from(t in PhoenixHxTodo.Todo, []), [t], (t.user_id == ^(user_id)) and (t.id == ^(id))))
    todos = PhoenixHxTodo.Repo.all(query)
    Enum.at(todos, 0)
  end
  def create_for_user(user, title, notes) do
    trimmed_title = StringTools.ltrim(StringTools.rtrim(title))
    trimmed_notes = StringTools.ltrim(StringTools.rtrim(notes))
    data = Kernel.struct(PhoenixHxTodo.Todo)
    params = %{title: trimmed_title, notes: trimmed_notes, completed: false, user_id: user.id}
    PhoenixHxTodo.Repo.insert(PhoenixHxTodo.Todo.changeset(data, params))
  end
  def toggle_for_user(user_id, id) do
    todo = get_for_user(user_id, id)
    if (Kernel.is_nil(todo)) do
      false
    else
      (case PhoenixHxTodo.Repo.update(PhoenixHxTodo.Todo.toggle_completed(todo)) do
        {:ok, _value} -> true
        {:error, _error} -> false
      end)
    end
  end
  def delete_for_user(user_id, id) do
    todo = get_for_user(user_id, id)
    if (Kernel.is_nil(todo)) do
      false
    else
      (case PhoenixHxTodo.Repo.delete(todo) do
        {:ok, _value} -> true
        {:error, _error} -> false
      end)
    end
  end
  def seed_defaults_for_user(user) do
    if (length(list_for_user(user.id)) > 0) do
      nil
    else
      defaults = PhoenixHxTodoHx.Live.TodoState.seed(PhoenixHxTodo.User.display_name(user))
      _g = 0
      Enum.each(defaults, fn item ->
        (case create_for_user(user, item.title, item.notes) do
          {:ok, created} ->
            cond do
              created.completed -> PhoenixHxTodo.Repo.update(PhoenixHxTodo.Todo.toggle_completed(created))
              true -> nil
            end
          {:error, _error} -> nil
        end)
      end)
    end
  end
  def view_items_for_user(user) do
    Enum.map(list_for_user(user.id), fn todo -> PhoenixHxTodoHx.Live.TodoState.item(todo.id, todo.title, todo.notes, PhoenixHxTodo.User.display_name(user), todo.completed) end)
  end
end

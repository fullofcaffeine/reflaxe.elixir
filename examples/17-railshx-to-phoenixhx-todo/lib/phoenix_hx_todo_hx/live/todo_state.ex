defmodule PhoenixHxTodoHx.Live.TodoState do
  use Phoenix.Component
  def seed(owner) do
    [item(1, "Ship typed Rails templates", "Port the HHX partial shape to inline HXX components.", owner, false), item(2, "Map strong params to changesets", "Document where Phoenix validates data differently.", owner, false), item(3, "Compare Turbo Streams and LiveView", "Keep DOM ownership on the server in both versions.", owner, true)]
  end
  def create(todos, id, title, notes, owner) do
    trimmed_title = StringTools.ltrim(StringTools.rtrim(title))
    if (trimmed_title == "") do
      todos
    else
      trimmed_notes = StringTools.ltrim(StringTools.rtrim(notes))
      [item(id, trimmed_title, trimmed_notes, owner, false)] ++ todos
    end
  end
  def toggle(todos, id) do
    Enum.map(todos, fn todo ->
      if (todo.id != id) do
        todo
      else
        item(todo.id, todo.title, todo.notes, todo.owner, not todo.completed)
      end
    end)
  end
  def delete_by_id(todos, id) do
    Enum.filter(todos, fn todo -> todo.id != id end)
  end
  def stats(todos) do
    open = 0
    completed = 0
    _g = 0
    {open, completed} = Enum.reduce(todos, {open, completed}, fn todo, {open_acc, completed_acc} ->
      if (todo.completed) do
        completed_acc = completed_acc + 1
        {open_acc, completed_acc}
      else
        open_acc = open_acc + 1
        {open_acc, completed_acc}
      end
    end)
    %{:open_count => open, :completed_count => completed, :typed_column_count => 5}
  end
  def item(id, title, notes, owner, completed) do
    %{:id => id, :title => title, :notes => notes, :owner => owner, :completed => completed, :row_class => (if (completed), do: "todo-item is-complete", else: "todo-item")}
  end
end

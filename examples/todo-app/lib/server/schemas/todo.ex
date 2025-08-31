defmodule Todo do
  def new() do
    %{:tags => [], :priority => "medium", :completed => false, :tags => [], :completed => false, :priority => "medium"}
  end
  def changeset(todo, params) do
    changeset = Ecto.Changeset.cast_changeset(todo, params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"])
    changeset = Ecto.Changeset.validate_required(changeset, ["title", "user_id"])
    changeset = Ecto.Changeset.validate_length(changeset, "title", %{:min => 3, :max => 200})
    changeset = Ecto.Changeset.validate_length(changeset, "description", %{:max => 1000})
    priority_values = [{:StringValue, "low"}, {:StringValue, "medium"}, {:StringValue, "high"}]
    changeset = Ecto.Changeset.validate_inclusion(changeset, "priority", priority_values)
    changeset = Ecto.Changeset.foreign_key_constraint(changeset, "user_id")
    changeset
  end
  def toggle_completed(todo) do
    params = %{}
    value = {:BoolValue, not todo.completed}
    Map.put(params, "completed", value)
    Todo.changeset(todo, params)
  end
  def update_priority(todo, priority) do
    params = %{}
    value = {:StringValue, priority}
    Map.put(params, "priority", value)
    Todo.changeset(todo, params)
  end
  def add_tag(todo, tag) do
    tags = if (todo.tags != nil), do: todo.tags, else: []
    tags.push(tag)
    params = %{}
    value = {:ArrayValue, tags.map(fn t -> {:StringValue, t} end)}
    Map.put(params, "tags", value)
    Todo.changeset(todo, params)
  end
end
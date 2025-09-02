defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema "todos" do
    field(:name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:confirmed_at, :naive_datetime)
    field(:last_login_at, :naive_datetime)
    field(:active, :boolean, [default: true])
    timestamps()
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
    params = Map.put(params, "completed", value)
    changeset(todo, params)
  end
  def update_priority(todo, priority) do
    params = %{}
    value = {:StringValue, priority}
    params = Map.put(params, "priority", value)
    changeset(todo, params)
  end
  def add_tag(todo, tag) do
    tags = if (todo.tags != nil), do: todo.tags, else: []
    tags.push(tag)
    params = %{}
    value = {:ArrayValue, Enum.map(tags, fn t -> {:StringValue, t} end)}
    params = Map.put(params, "tags", value)
    changeset(todo, params)
  end
end
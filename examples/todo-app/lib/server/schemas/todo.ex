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
    cs = Changeset_Impl_._new(todo, params)
    Changeset_Impl_.validate_length(Changeset_Impl_.validate_length(Changeset_Impl_.validate_required(cs, ["title", "userId"]), "title", %{:min => 3, :max => 200}), "description", %{:max => 1000})
  end
  def toggle_completed(todo) do
    params = %{:completed => not todo.completed}
    Todo.changeset(todo, params)
  end
  def update_priority(todo, priority) do
    params = %{:priority => priority}
    Todo.changeset(todo, params)
  end
  def add_tag(todo, tag) do
    tags = if (todo.tags != nil) do
  todo.tags
else
  []
end
    tags = tags ++ [tag]
    params = %{:tags => tags}
    Todo.changeset(todo, params)
  end
end
defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema "todos" do
    field(:title, :string)
    field(:description, :string)
    field(:completed, :boolean)
    field(:priority, :string)
    field(:due_date, :string)
    field(:tags, {:array, :string})
    field(:user_id, :integer)
    timestamps()
  end
  def changeset(todo, params) do
    cs = Changeset_Impl_._new(todo, params)
    Changeset_Impl_.validate_length(Changeset_Impl_.validate_length(Changeset_Impl_.validate_required(cs, ["title", "userId"]), "title", %{:min => 3, :max => 200}), "description", %{:max => 1000})
  end
  def toggle_completed(todo) do
    changeset(todo, (%{:completed => not todo.completed}))
  end
  def update_priority(todo, priority) do
    changeset(todo, (%{:priority => priority}))
  end
  def add_tag(todo, tag) do
    tags = if (todo.tags != nil) do
  todo.tags
else
  []
end
    tags = tags ++ [tag]
    params = %{:tags => tags}
    changeset(todo, params)
  end
end